// ApexCharts manipula colores internamente (gradientes, opacidad) asumiendo
// hex/rgb — pasarle un oklch() crudo (así es como daisyUI define --color-*,
// ver app/assets/tailwind/daisyui-theme.mjs) puede fallar en esas rutas
// aunque el SVG lo pinte bien de entrada. Un <canvas> resuelve cualquier
// color CSS válido a RGB concreto sin importar el formato de entrada — lo
// usamos como conversor universal, nunca se dibuja en pantalla.
const canvas = document.createElement("canvas")
canvas.width = 1
canvas.height = 1
const ctx = canvas.getContext("2d")

function resolveColor(cssColor) {
  ctx.fillStyle = cssColor
  ctx.fillRect(0, 0, 1, 1)
  const [ r, g, b ] = ctx.getImageData(0, 0, 1, 1).data
  return `rgb(${r}, ${g}, ${b})`
}

function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}

function isDarkMode() {
  return getComputedStyle(document.documentElement).colorScheme.includes("dark")
}

// Orden en que ApexCharts asigna un color a cada serie cuando hay más de
// una — si agregás más series que colores, ApexCharts repite el ciclo.
const SERIES_VARS = [
  "--color-primary", "--color-secondary", "--color-accent",
  "--color-info", "--color-success", "--color-warning", "--color-error"
]

export function readThemeColors() {
  return {
    series: SERIES_VARS.map((name) => resolveColor(cssVar(name))),
    content: resolveColor(cssVar("--color-base-content")),
    border: resolveColor(cssVar("--color-base-300")),
    mode: isDarkMode() ? "dark" : "light"
  }
}