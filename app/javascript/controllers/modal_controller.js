import { Controller } from "@hotwired/stimulus"

// Uso: <button data-controller="modal" data-modal-id-value="mi_modal" data-action="modal#open">Abrir</button>
export default class extends Controller {
  static values = { id: String }

  open() {
    document.getElementById(this.idValue)?.showModal()
  }
}
