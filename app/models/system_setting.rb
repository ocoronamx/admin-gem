# Configuración global del sistema — un solo registro (singleton), no un
# recurso con índice/CRUD normal. Se accede siempre vía SystemSetting.instance.
class SystemSetting < ApplicationRecord
  include Auditable

  AVAILABLE_THEMES = %w[light dark].freeze

  validates :active_theme, inclusion: { in: AVAILABLE_THEMES }
  validate :singleton, on: :create

  def self.instance
    first_or_create!(active_theme: "light")
  end

  def brand_overrides?
    brand_primary.present? || brand_secondary.present? || brand_accent.present?
  end

  private

  def singleton
    errors.add(:base, "Solo puede existir una configuración de sistema") if SystemSetting.exists?
  end
end
