# Controlador base de la aplicación del cual heredan todos los demás controladores.
# Maneja configuraciones globales como restricciones de navegador, caching, el layout principal,
# la autorización con Pundit, y la inicialización de preferencias de la interfaz (tema visual y estado de la barra lateral).
class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Method
  include Filterable

  # Restringe el acceso únicamente a navegadores modernos con soporte completo para tecnologías web recientes.
  allow_browser versions: :modern

  # Invalida las etiquetas ETag para respuestas HTML automáticamente si cambia el mapa de importaciones.
  stale_when_importmap_changes

  layout "admin"

  before_action :set_theme
  before_action :set_sidebar_state
  before_action :set_current_request

  after_action :verify_pundit_authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_theme, :sidebar_collapsed?

  private

  # Expone el request actual en Current para que un modelo (ej. Auditable)
  # pueda registrar IP/user-agent sin que cada controller se lo pase a mano.
  def set_current_request
    Current.request = request
  end

  # Devuelve el tema visual activo durante el ciclo de vida del request.
  #
  # @return [String] "light" o "dark".
  # @note Expuesto como `helper_method` para su consumo directo en plantillas ERB.
  def current_theme
    @current_theme
  end

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

  # Indica si la barra lateral de navegación debe renderizarse en su versión colapsada.
  #
  # @return [Boolean] true si la barra lateral está contraída, false si está expandida.
  # @note Expuesto como `helper_method` para su consumo directo en plantillas ERB.
  def sidebar_collapsed?
    @sidebar_collapsed
  end

  # Usuario que Pundit usa en policies y scopes. Por defecto Pundit llama a
  # `current_user`, que no existe en nuestra app (usamos `Current.user`, del
  # generador de autenticación nativo de Rails 8).
  #
  # @return [User, nil]
  def pundit_user
    Current.user
  end

  # Maneja los rechazos de autorización de Pundit de forma consistente en toda la app.
  def user_not_authorized
    flash[:alert] = "No tienes permiso para realizar esta acción."
    redirect_back fallback_location: root_path
  end

  def verify_pundit_authorization
    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end
end
