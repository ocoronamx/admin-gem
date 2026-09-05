class AuditLogsController < ApplicationController
  filterable_by action: :by_action

  def index
    authorize AuditLog
    scope = apply_filters(policy_scope(AuditLog)).order(created_at: :desc)
    @pagy, @audit_logs = pagy(:offset, scope)
  end
end