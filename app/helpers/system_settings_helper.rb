module SystemSettingsHelper
  BRAND_TOKENS = { brand_primary: "primary", brand_secondary: "secondary", brand_accent: "accent" }.freeze

  # <style> con overrides de color de marca sobre el tema activo. Vacío si
  # el Super no configuró ningún override — el tema compilado manda solo.
  def brand_override_styles
    setting = SystemSetting.instance
    return unless setting.brand_overrides?

    declarations = BRAND_TOKENS.filter_map do |attribute, token|
      value = setting.public_send(attribute)
      next if value.blank?

      "--color-#{token}: #{value}; --color-#{token}-content: #{readable_content_color_for(value)};"
    end

    tag.style(
      "[data-theme=\"#{setting.active_theme}\"] { #{declarations.join(' ')} }".html_safe,
      nonce: content_security_policy_nonce
    )
  end

  private

  # Blanco o negro según la luminancia relativa (WCAG) del color elegido —
  # no optimiza el ratio de contraste, es una guardarraíl simple para que un
  # Super no pueda dejar texto ilegible por accidente al elegir un color.
  def readable_content_color_for(hex)
    r, g, b = hex.delete("#").scan(/../).map { |c| c.to_i(16) / 255.0 }
    linear = [r, g, b].map { |c| c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    luminance = 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    luminance > 0.5 ? "#0a0a0a" : "#fafafa"
  end
end
