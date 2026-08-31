import { Controller } from "@hotwired/stimulus"

// Seam de extensión reservado por el ADR: hoy no envuelve nada, los inputs de
// fecha son <input type="date"> nativos sin JS (Flatpickr está abandonado,
// ver setup_09_forms.md). Si en el futuro un caso puntual necesita más que
// eso (rango visual, calendario inline), se evalúa una librería concreta en
// ese momento y se implementa aquí — AdminFormBuilder y las vistas no cambian,
// solo agregás data: { controller: "datepicker" } al campo que lo necesite.
export default class extends Controller {
  connect() {
    // Intencionalmente vacío. Ver comentario de arriba.
  }
}