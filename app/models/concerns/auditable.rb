# Hook genérico de auditoría vía ActiveModel::Dirty. Incluir en cualquier
# modelo que necesite dejar rastro de sus cambios — ver User/Role para el
# uso real, y audit_excludes para ocultar columnas sensibles del diff.
module Auditable
  extend ActiveSupport::Concern

  included do
    class_attribute :audit_excluded_columns, default: %w[created_at updated_at]

    after_create  { log_audit("create", saved_changes.except(*audit_excluded_columns)) }
    after_update  { log_audit("update", saved_changes.except(*audit_excluded_columns)) if audit_relevant_changes? }
    after_destroy { log_audit("destroy", attributes.except(*audit_excluded_columns)) }
  end

  class_methods do
    # Columnas que nunca deben aparecer en el diff — contraseñas, tokens,
    # cualquier cosa sensible. created_at/updated_at ya están excluidas
    # por defecto (puro ruido, no una decisión de negocio).
    def audit_excludes(*columns)
      self.audit_excluded_columns += columns.map(&:to_s)
    end
  end

  private

  def audit_relevant_changes?
    (saved_changes.keys - audit_excluded_columns).any?
  end

  def log_audit(action, changes_data)
    AuditLog.create!(
      user: Current.user,
      resource: self,
      action: action,
      changes_data: changes_data,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  end
end
