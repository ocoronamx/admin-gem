module BadgeHelper
  # Ej: status_badge("Activo", variant: :success)
  #     status_badge("Desactivado", variant: :ghost, size: :sm)
  def status_badge(label, variant:, soft: true, size: nil)
    soft = false if variant.to_s == "ghost"
    classes = ["badge", "badge-#{variant}", soft ? "badge-soft" : nil, size ? "badge-#{size}" : nil].compact.join(" ")
    content_tag(:span, label, class: classes)
  end
end
