import { Controller } from "@hotwired/stimulus"

/**
 * Controlador de Stimulus para alternar y persistir el estado de la barra lateral (sidebar).
 *
 * Alterna el estado entre "expanded" y "collapsed" modificando el atributo `data-sidebar` 
 * en el elemento `<html>` al instante (en el cliente) y lo persiste en una cookie de 1 año 
 * para que Rails pueda leerlo en peticiones subsiguientes.
 *
 * @extends Controller
 *
 * @example
 *   <button data-controller="sidebar-toggle" data-action="click->sidebar-toggle#toggle">
 *     Alternar Sidebar
 *   </button>
 */
export default class extends Controller {
  /**
   * Lee el estado actual desde el DOM, calcula el estado opuesto,
   * guarda la preferencia en cookies y actualiza el atributo `data-sidebar`.
   *
   * @returns {void}
   */
  toggle() {
    const collapsed = document.documentElement.getAttribute("data-sidebar") === "collapsed"
    const next = collapsed ? "expanded" : "collapsed"
    document.cookie = `sidebar=${next}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-sidebar", next)
  }
}