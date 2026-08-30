  # DONE:
  #   Setup 0  — Arquitectura                    hecho
  #   Setup 1  — Preparación de entorno          hecho
  #   Setup 2  — Inicialización Rails            hecho (admin-gem, Ruby 3.4.10, Rails 8.1, PG 17)
  #   Setup 3  — Base de datos                   hecho (citext, pgcrypto)
  #   Setup 4  — Frontend / Design System        hecho (Tailwind v4 + DaisyUI v5, tokens, dark/light)
  #   Setup 5  — Layout administrativo           hecho (sidebar, header, breadcrumbs, mobile nav)
  #
  # CURRENT:
  #   Setup 6  — Authentication                  (generador nativo Rails 8 + hardening)
  #
  # TODO:
  #   Setup 7  — Authorization                   (Pundit + Role/Permission)
  #   Setup 8  — Componentes                     (partials/helpers/Stimulus del design system)
  #   Setup 9  — Forms                           (form builder, Tom Select, inputs nativos de fecha)
  #   Setup 10 — Tables / Filtros / Pagy         (tabla reutilizable, filtros por allowlist)
  #   Setup 11 — Charts                          (wrapper ApexCharts v6.x)
  #   Setup 12 — Dashboard                       (demo data, claramente marcada)
  #   Setup 13 — Usuarios                        (módulo de referencia)
  #   Setup 14 — Auditoría                       (Auditable concern + AuditLog propio)
  #   Setup 15 — Testing                         (RSpec, factories, qué probar y qué no)
  #   Setup 16 — Security hardening              (CSP, headers, Brakeman en CI)
  #   Setup 17 — CI/CD                           (GitHub Actions: lint → security → tests → build)
  #   Setup 18 — Docker / Deployment             (Dockerfile + Kamal 2)
  #   Setup 19 — Documentation                   (README, CONTRIBUTING, SECURITY, CHANGELOG, docs/adr/)
  #   Setup 20 — Revisión final de arquitectura


# Controlador base de la aplicación del cual heredan todos los demás controladores.
# Maneja configuraciones globales como restricciones de navegador, caching, el layout principal,
# y la inicialización de preferencias de la interfaz (tema visual y estado de la barra lateral).
class ApplicationController < ActionController::Base
  # Restringe el acceso únicamente a navegadores modernos con soporte completo para tecnologías web recientes.
  allow_browser versions: :modern

  # Invalida las etiquetas ETag para respuestas HTML automáticamente si cambia el mapa de importaciones.
  stale_when_importmap_changes

  layout "admin"

  before_action :set_theme
  before_action :set_sidebar_state

  helper_method :current_theme, :sidebar_collapsed?

  private

  # Inicializa la variable de instancia con la preferencia del tema visual.
  # Valida que la cookie de tema sea estricta ("light" o "dark") para evitar valores arbitrarios,
  # aplicando "light" como fallback de seguridad.
  #
  # @return [String] El tema activo ("light" o "dark").
  def set_theme
    @current_theme = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
  end

  # Inicializa la variable de instancia con el estado de despliegue de la barra lateral
  # leyendo la preferencia persistida en las cookies.
  #
  # @return [Boolean] true si la cookie equivale a "collapsed", de lo contrario false.
  def set_sidebar_state
    @sidebar_collapsed = cookies[:sidebar] == "collapsed"
  end

  # Devuelve el tema visual activo durante el ciclo de vida del request.
  #
  # @return [String] "light" o "dark".
  # @note Expuesto como `helper_method` para su consumo directo en plantillas ERB.
  def current_theme
    @current_theme
  end

  # Indica si la barra lateral de navegación debe renderizarse en su versión colapsada.
  #
  # @return [Boolean] true si la barra lateral está contraída, false si está expandida.
  # @note Expuesto como `helper_method` para su consumo directo en plantillas ERB.
  def sidebar_collapsed?
    @sidebar_collapsed
  end
end
