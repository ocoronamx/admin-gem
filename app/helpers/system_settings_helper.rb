module SystemSettingsHelper
  COLOR_TOKENS = %w[primary secondary accent].freeze

  # <style> con los overrides de color de marca sobre el tema activo AHORA
  # MISMO (compuesto: base_theme + color_mode) — nunca genera los 4 combos
  # posibles, solo el que está realmente activo. Sin nonce: depende de
  # style-src :unsafe_inline (ver config/initializers/content_security_policy.rb).
  def brand_override_styles
    setting = SystemSetting.instance
    mode = setting.color_mode
    return unless setting.custom_colors?(mode)

    colors = setting.colors_for(mode)
    declarations = COLOR_TOKENS.filter_map do |token|
      value = colors[token]
      next if value.blank?

      "--color-#{token}: #{value}; --color-#{token}-content: #{readable_content_color_for(value)};"
    end
    return if declarations.empty?

    tag.style("[data-theme=\"#{setting.theme_name}\"] { #{declarations.join(' ')} }".html_safe)
  end

  # Blanco o negro según la luminancia relativa (WCAG) del color elegido —
  # guardarraíl simple, no optimiza el ratio de contraste. Solo aplica a
  # colores hex reales (los custom); los default vienen en OKLCH y no pasan
  # por acá, solo se muestran como swatch de referencia en la vista.
  def readable_content_color_for(hex)
    return "#0a0a0a" unless hex.start_with?("#")

    r, g, b = hex.delete("#").scan(/../).map { |c| c.to_i(16) / 255.0 }
    linear = [ r, g, b ].map { |c| c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    luminance = 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    luminance > 0.5 ? "#0a0a0a" : "#fafafa"
  end
end
