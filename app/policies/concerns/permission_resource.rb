# Deriva el nombre del recurso ("roles", "users"...) a partir del nombre de
# la clase de policy que lo incluye, y construye la clave de permiso
# correspondiente ("roles.view", "roles.manage").
module PermissionResource
  private

  def resource_name
    self.class.name.sub(/Policy(::Scope)?\z/, "").underscore.pluralize
  end

  def permission_key(level)
    "#{resource_name}.#{level}"
  end

  def permitted?(level)
    user&.permits?(permission_key(level))
  end
end
