import { Controller } from "@hotwired/stimulus"

// TRANSICIÓN (Paso 1 de 4): sigue siendo la cookie personal, "classic-"
// hardcodeado hasta el Paso 3.
export default class extends Controller {
  persist(event) {
    const theme = event.target.checked ? "dark" : "light"
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-theme", `classic-${theme}`)

    window.dispatchEvent(new CustomEvent("theme:change"))
  }
}