# Configuración global del sistema — un solo registro (singleton), no un
# recurso con índice/CRUD normal. Se accede siempre vía SystemSetting.instance.
class SystemSetting < ApplicationRecord
  include Auditable

  has_one_attached :logo
  has_one_attached :favicon

  BASE_THEMES = %w[classic ink_bronze].freeze
  COLOR_MODES = %w[light dark].freeze

  # Valores reales de cada tema base, en OKLCH — tienen que coincidir a mano
  # con application.css (Paso 1). No hay forma de leer las custom properties
  # ya compiladas desde Ruby en boot time, así que esto se mantiene
  # sincronizado manualmente si se edita la paleta.
  BASE_THEME_DEFAULTS = {
    "classic" => {
      "light" => { "primary" => "oklch(45% 0.15 264)", "secondary" => "oklch(55% 0.04 255)", "accent" => "oklch(70% 0.14 200)" },
      "dark"  => { "primary" => "oklch(70% 0.14 264)", "secondary" => "oklch(70% 0.03 255)", "accent" => "oklch(75% 0.13 200)" }
    },
    "ink_bronze" => {
      "light" => { "primary" => "oklch(48% 0.13 60)", "secondary" => "oklch(42% 0.03 250)", "accent" => "oklch(48% 0.09 190)" },
      "dark"  => { "primary" => "oklch(72% 0.13 65)", "secondary" => "oklch(72% 0.02 250)", "accent" => "oklch(72% 0.1 190)" }
    }
  }.freeze

  validates :app_name, presence: true
  validates :base_theme, inclusion: { in: BASE_THEMES }
  validates :color_mode, inclusion: { in: COLOR_MODES }
  validates :logo, content_type: %w[image/png image/jpeg image/svg+xml image/webp], size: { less_than: 2.megabytes }
  validates :favicon, content_type: %w[image/png image/x-icon image/vnd.microsoft.icon], size: { less_than: 512.kilobytes }
  validate :singleton, on: :create

  before_validation :sync_default_colors, if: :base_theme_changed?

  def self.instance
    first_or_create!(app_name: "Admin Gem")
  end

  # "classic-light", "ink_bronze-dark"... — el data-theme real a renderizar
  # (todavía sin conectar a nada — eso es el Paso 3).
  def theme_name
    "#{base_theme}-#{color_mode}"
  end

  # Custom si existe; si no, el default del tema. Para pintar swatches de
  # referencia — no para precargar el color picker (ver nota del Paso 3
  # sobre por qué OKLCH no sirve como value de un <input type="color">).
  def colors_for(mode)
    public_send("custom_colors_#{mode}").presence || public_send("default_colors_#{mode}")
  end

  def custom_colors?(mode)
    public_send("custom_colors_#{mode}").present?
  end

  # No persiste sola — el controller (Paso 3) la combina con el resto de
  # los atributos y guarda todo junto en un solo `save`.
  def assign_custom_colors(mode, colors)
    assign_attributes(
      "previous_colors_#{mode}" => public_send("custom_colors_#{mode}"),
      "custom_colors_#{mode}" => colors.compact_blank
    )
  end

  def restore_previous_colors!(mode)
    update!("custom_colors_#{mode}" => public_send("previous_colors_#{mode}"))
  end

  def reset_colors_to_theme_default!(mode)
    assign_custom_colors(mode, {})
    save!
  end

  private

  def sync_default_colors
    COLOR_MODES.each { |mode| assign_attributes("default_colors_#{mode}" => BASE_THEME_DEFAULTS.fetch(base_theme).fetch(mode)) }
  end

  def singleton
    errors.add(:base, "Solo puede existir una configuración de sistema") if SystemSetting.exists?
  end
end
