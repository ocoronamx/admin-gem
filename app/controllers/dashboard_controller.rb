class DashboardController < ApplicationController
  # Landing compartida, no un recurso administrable — mismo criterio que
  # PagesController para /styleguide.
  skip_after_action :verify_pundit_authorization

  def index
    @stats = {
      users: User.count,
      roles: Role.count,
      permissions: Permission.count,
      sessions: Session.count
    }

    # Datos de ejemplo — no existe todavía una fuente real de "actividad"
    # (eso llega con AuditLog en la Fase 14). Reemplazá esto por una consulta
    # real en cuanto haya un evento que valga la pena graficar. Marcado
    # también en la vista (badge "Datos de ejemplo") — no alcanza con el
    # comentario acá.
    @demo_activity = (6.days.ago.to_date..Date.current).map { |date| { date: date, value: rand(20..80) } }
  end
end
