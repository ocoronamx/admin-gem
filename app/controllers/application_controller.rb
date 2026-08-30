class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # DONE:
  #   Fase 0  — Arquitectura                    hecho
  #   Fase 1  — Inicialización Rails            hecho (admin-gem, Ruby 3.4.10, Rails 8.1, PG 17)
  #   Fase 2  — Base de datos                   ← ahora

  # CURRENT:
  #   Fase 3  — Frontend / Design System        (Tailwind v4 + DaisyUI v5, tokens, dark/light)

  # TODO:
  #   Fase 4  — Layout administrativo           (sidebar, header, breadcrumbs, mobile nav)
  #   Fase 5  — Authentication                  (generador nativo Rails 8 + hardening)
  #   Fase 6  — Authorization                   (Pundit + Role/Permission)
  #   Fase 7  — Componentes                     (partials/helpers/Stimulus del design system)
  #   Fase 8  — Forms                           (form builder, Tom Select, inputs nativos de fecha)
  #   Fase 9  — Tables / Filtros / Pagy         (tabla reutilizable, filtros por allowlist)
  #   Fase 10 — Charts                          (wrapper ApexCharts v6.x)
  #   Fase 11 — Dashboard                       (demo data, claramente marcada)
  #   Fase 12 — Usuarios                        (módulo de referencia)
  #   Fase 13 — Auditoría                       (Auditable concern + AuditLog propio)
  #   Fase 14 — Testing                         (RSpec, factories, qué probar y qué no)
  #   Fase 15 — Security hardening              (Rack::Attack, CSP, headers, Brakeman en CI)
  #   Fase 16 — CI/CD                           (GitHub Actions: lint → security → tests → build)
  #   Fase 17 — Docker / Deployment             (Dockerfile + Kamal 2)
  #   Fase 18 — Documentation                   (README, CONTRIBUTING, SECURITY, CHANGELOG, docs/adr/)
  #   Fase 19 — Revisión final de arquitectura

  before_action :set_theme

  helper_method :current_theme

  private

  def set_theme
    @current_theme = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
  end

  def current_theme
    @current_theme
  end
end
