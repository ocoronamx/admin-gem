class UserPolicy < ApplicationPolicy
  # No podés desactivarte/reactivarte a vos mismo — evita autobloquearte el
  # acceso por accidente. La vista consulta esto para directamente no mostrar
  # el botón (ver app/views/users/_actions.html.erb).
  def toggle_active?
    permitted?(:manage) && record != user
  end

  class Scope < ApplicationPolicy::Scope
  end
end
