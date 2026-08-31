import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Envuelve un <select> nativo con Tom Select. Uso normal: a través de
// `form.tom_select` (ver app/form_builders/admin_form_builder.rb), que ya
// agrega data-controller="tom-select" y el JSON de configuración por vos.
export default class extends Controller {
  static values = { options: Object }

  connect() {
    this.tomSelect = new TomSelect(this.element, this.optionsValue)
  }

  disconnect() {
    this.tomSelect?.destroy()
  }
}