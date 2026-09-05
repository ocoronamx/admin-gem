module AuditLogsHelper
  # { "attr" => [viejo, nuevo] } → "attr: viejo → nuevo", separado por comas.
  # Suficiente para una tabla — no pretende ser un diff completo.
  def format_audit_changes(changes_data)
    return "—" if changes_data.blank?

    changes_data.map { |attr, value| "#{attr}: #{Array(value).join(' → ')}" }.join(", ")
  end

  def audit_action_badge(action)
    css = { "create" => "badge-success", "update" => "badge-info", "destroy" => "badge-error" }.fetch(action, "badge-ghost")
    content_tag :span, action, class: "badge badge-sm #{css}"
  end
end
