import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"
import { readThemeColors } from "charts/theme_colors"

// Wrapper de ApexCharts integrado con los tokens de DaisyUI. Uso normal: a
// través de `chart_tag` (ver app/helpers/charts_helper.rb), que ya agrega
// data-controller="chart" y los tres values de acá abajo.
export default class extends Controller {
  static values = { type: String, series: Array, options: Object }

  connect() {
    this.chart = new ApexCharts(this.element, this.buildOptions())
    this.chart.render()

    // theme_toggle_controller dispara esto al cambiar data-theme — sin esto,
    // un chart ya renderizado se queda con los colores del tema anterior.
    this.onThemeChange = () => this.chart.updateOptions(this.buildOptions())
    window.addEventListener("theme:change", this.onThemeChange)
  }

  disconnect() {
    window.removeEventListener("theme:change", this.onThemeChange)
    this.chart?.destroy()
  }

  // Superficial a propósito: los defaults de acá nunca tocan xaxis/yaxis/
  // labels/plotOptions, así que lo que la vista pase en `options` para esas
  // claves nunca choca con nada. `chart` sí se mezcla un nivel más adentro
  // porque `type` tiene que sobrevivir aunque la vista agregue, por ejemplo,
  // chart: { height: 300 }.
  buildOptions() {
    const palette = readThemeColors()

    const base = {
      chart: { type: this.typeValue, background: "transparent", toolbar: { show: false }, fontFamily: "inherit" },
      colors: palette.series,
      theme: { mode: palette.mode },
      grid: { borderColor: palette.border },
      tooltip: { theme: palette.mode }
    }

    return {
      ...base,
      ...this.optionsValue,
      series: this.seriesValue,
      chart: { ...base.chart, ...(this.optionsValue.chart || {}) }
    }
  }
}