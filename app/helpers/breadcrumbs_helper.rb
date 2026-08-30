# Helper para gestionar la navegación de "migas de pan" (breadcrumbs).
# Permite acumular la ruta de navegación durante el ciclo de vida del request
# (desde controladores o vistas) para luego renderizarla en el layout.
module BreadcrumbsHelper
  # Agrega un nuevo elemento a la lista de breadcrumbs.
  #
  # @param label [String] El texto visible del breadcrumb (ej. "Inicio", "Usuarios").
  # @param path [String, nil] La ruta o URL del enlace.
  #   Si se omite (nil), generalmente se interpreta como el elemento actual o final de la lista.
  # @return [Array<Hash>] La lista actualizada de breadcrumbs.
  #
  # @example
  #   add_breadcrumb("Inicio", root_path)
  #   add_breadcrumb("Perfil", user_path(@user))
  def add_breadcrumb(label, path = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { label: label, path: path }
  end

  # Devuelve la colección de breadcrumbs acumulados hasta el momento.
  #
  # @return [Array<Hash>] Un arreglo de hashes, donde cada hash contiene
  #   las llaves :label y :path. Retorna un arreglo vacío si no hay elementos.
  #
  # @example Retorno
  #   # => [{ label: "Inicio", path: "/" }, { label: "Perfil", path: nil }]
  def breadcrumbs
    @breadcrumbs || []
  end
end
