import { Controller } from "@hotwired/stimulus"

// Persiste la preferencia de tema en una cookie legible por Rails,
// y actualiza data-theme al instante (sin esperar al próximo request).
export default class extends Controller {
  persist(event) {
    const theme = event.target.checked ? "dark" : "light"
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-theme", theme)

    // Cualquier chart en pantalla (chart_controller.js) escucha esto para
    // releerse los colores del tema nuevo y repintarse solo.
    window.dispatchEvent(new CustomEvent("theme:change"))
  }
}
