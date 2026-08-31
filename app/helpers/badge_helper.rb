module BadgeHelper
  # Ej: status_badge("Activo", variant: :success)
  def status_badge(label, variant:)
    content_tag(:span, label, class: "badge badge-#{variant}")
  end
end
