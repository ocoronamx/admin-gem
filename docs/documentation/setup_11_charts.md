# Setup 11 — Charts

## Objetivo

Wrapper de ApexCharts v6.x (`chart_tag` + `chart_controller.js`) que lee su paleta de colores del tema DaisyUI activo en tiempo real — nada de colores hardcodeados en cada chart — y se repinta solo cuando alguien cambia de tema. Dogfoodeado en `/styleguide`.

## Decisiones arquitectónicas

* **Sin gema Ruby, vendorizado vía importmap**: busqué un equivalente a `tom-select-rails` para ApexCharts y no existe — es una librería JS pura sin necesidad de lógica de servidor. Mismo mecanismo que Tom Select en Setup 9: `bin/importmap pin` vendoriza el build ESM localmente, sin CDN en runtime.
* **v6.10.0 (la v6.x actual)**: confirmé que la serie v6 sigue activa y es la fijada en tu ADR — no hay salto de major version que reconsiderar.
* **Colores resueltos vía `<canvas>`, no leídos como string crudo**: las variables de daisyUI (`--color-primary`, etc.) son `oklch(...)`. ApexCharts manipula color internamente (gradientes, opacidad) asumiendo hex/rgb en varias rutas de su código — pasarle el string oklch tal cual puede fallar ahí aunque el SVG lo renderice bien a simple vista. Un `<canvas>` de 1×1 resuelve *cualquier* color CSS válido a RGB concreto usando el mismo motor de parseo de color del navegador — funciona sin importar qué formato usen las variables, hoy o en el futuro.
* **Un solo `chart_tag`/`chart_controller.js` para todos los tipos de chart** (`type:` es un parámetro, no una clase distinta) — evita `line_chart_tag`, `donut_chart_tag`, etc. duplicando lo mismo. Coherente con el criterio de "no dupliques el wrapper" que ya usaste implícitamente en `components/table`.
* **`options` pasa tal cual a ApexCharts, sin traducir ni validar claves**: cualquier opción que la librería acepte (`xaxis`, `labels`, `plotOptions`, `annotations`...) funciona sin tocar el wrapper. El wrapper solo resuelve una cosa (colores del tema) — todo lo demás es la API real de ApexCharts, sin capa de traducción que mantener.
* **Reactividad vía evento custom (`theme:change`), no `MutationObserver`**: `theme_toggle_controller.js` ya sabe exactamente cuándo cambia el tema — que lo anuncie es más simple y explícito que hacer que cada chart vigile el DOM por su cuenta.
* **`theme.mode` nativo de ApexCharts para el resto de la UI del chart** (grid, tooltip, texto), en vez de fijar manualmente cada color de eje/leyenda — reduce superficie propia y evita choques de merge cuando una vista pasa sus propias opciones de `xaxis`/`yaxis` (ver más abajo).

## Alternativas consideradas

* **Chart.js** (ya disponible en el sandbox de artifacts, pero no acá) → descartado: no es lo que fijaste en el ADR, y ApexCharts ya trae theming/gradientes/tooltips más resueltos out of the box para un panel admin.
* **Pasar los colores del tema como string `oklch(...)` directo a `colors: [...]`** → descartado por el riesgo de compatibilidad interna de ApexCharts explicado arriba.
* **`getComputedStyle(...).color` como conversor** (setear el valor en un elemento oculto y leer el resultado) → descartado: en navegadores nuevos el valor computado puede devolverse todavía en formato `oklch(...)` en vez de normalizarse a rgb, así que no resuelve el problema de forma confiable. El canvas sí, porque `getImageData` siempre devuelve bytes RGB concretos sin importar el formato de entrada.
* **Deep-merge genérico de opciones** (tipo `lodash.merge`) → descartado: agregaría una dependencia solo para mezclar objetos de configuración; con no tocar `xaxis`/`yaxis`/`labels` en los defaults del wrapper, un merge superficial ya alcanza (ver Archivos).

## Comandos

```bash
bin/importmap pin apexcharts@6.10.0
bin/importmap pin tom-select@2.6.2
```

```bash
# 1. Reemplaza el archivo modular por el bundle UMD completo
curl -o vendor/javascript/tom-select.js \
  "https://unpkg.com/tom-select@2.6.2/dist/js/tom-select.complete.min.js"

# 2. Conviértelo en ES module: el UMD deja el valor en `globalThis.TomSelect`,
#    solo hace falta exportarlo
echo 'export default globalThis.TomSelect;' >> vendor/javascript/tom-select.js

# 3. Ya no necesitas los paquetes que jspm agregó para la versión modular
rm vendor/javascript/@orchidjs--sifter.js vendor/javascript/@orchidjs--unicode-variants.js
```

## Archivos

**config/importmap.rb** — agrega (el pin de `apexcharts` lo escribe el comando de arriba; `charts/theme_colors` es manual, mismo patrón que `pin "application"` — resuelve a `app/javascript/charts/theme_colors.js` sin necesitar `to:`):

```ruby
# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "turbo_confirm"
pin "tom-select" # @2.6.2 — UMD vendored a mano (unpkg), no el build modular de jspm
pin "charts/theme_colors"
pin "apexcharts" # @6.10.0
```

**app/javascript/charts/theme_colors.js** (nuevo):

```bash
mkdir app/javascript/charts
touch app/javascript/charts/theme_colors.js
```

```javascript
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
```

**app/javascript/controllers/chart_controller.js** (nuevo):

```bash
touch app/javascript/controllers/chart_controller.js
```

```javascript
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
```

**app/javascript/controllers/theme_toggle_controller.js** — agrega el dispatch al final de `persist`:

```javascript
  persist(event) {
    const theme = event.target.checked ? "dark" : "light"
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-theme", theme)

    // Cualquier chart en pantalla (chart_controller.js) escucha esto para
    // releerse los colores del tema nuevo y repintarse solo.
    window.dispatchEvent(new CustomEvent("theme:change"))
  }
```

**app/helpers/charts_helper.rb** (nuevo):

```bash
touch app/helpers/charts_helper.rb
```

```ruby
module ChartsHelper
  # Contenedor para un chart de ApexCharts. El JS (chart_controller.js) lee
  # type/series/options desde los data-* y arma la configuración completa —
  # acá no se decide ningún color, eso sale del tema activo en tiempo real.
  #
  #   chart_tag type: :line, series: [{ name: "Ventas", data: [1, 2, 3] }],
  #     xaxis: { categories: %w[Ene Feb Mar] }
  #
  # `options` viaja tal cual a ApexCharts — cualquier clave que la librería
  # acepte funciona sin tener que agregar nada acá.
  def chart_tag(type:, series:, id: nil, height: 320, **options)
    content_tag :div, "",
      id: id,
      style: "min-height: #{height}px",
      data: {
        controller: "chart",
        chart_type_value: type.to_s,
        chart_series_value: series,
        chart_options_value: options
      }
  end
end
```

**app/views/pages/styleguide.html.erb** — agrega después de la sección de Formularios, antes del render del Modal:

```erb
  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Charts (ApexCharts)</h2>
    <p class="text-sm text-base-content/60 -mt-2">
      Los colores salen del tema activo — probá el toggle de arriba, se repintan solos.
    </p>

    <div class="grid sm:grid-cols-2 gap-4">
      <%= chart_tag type: :line, height: 240,
            series: [
              { name: "Usuarios activos", data: [ 30, 40, 35, 50, 49, 60, 70 ] },
              { name: "Sesiones", data: [ 20, 28, 25, 33, 36, 44, 52 ] }
            ],
            xaxis: { categories: %w[Lun Mar Mié Jue Vie Sáb Dom] } %>

      <%= chart_tag type: :donut, height: 240,
            series: [ 44, 33, 23 ],
            labels: %w[Admin Editor Invitado] %>
    </div>
  </section>
```

**spec/helpers/charts_helper_spec.rb** (nuevo, pending — mismo criterio que el resto de los helpers de UI):

```ruby
require "rails_helper"

RSpec.describe ChartsHelper, type: :helper do
  pending "add some examples to (or delete) #{__FILE__}"
end
```

**docs/conventions/charts.md** (nuevo):

```markdown
# Convenciones de charts — admin-gem

## Cómo agregar un chart
`chart_tag type: :line, series: [...], **opciones_de_apexcharts`. `type`/`series`
son obligatorios; cualquier otra clave (`xaxis`, `labels`, `plotOptions`,
`chart: { height: ... }`) viaja tal cual a ApexCharts.

```erb
<%= chart_tag type: :line,
      series: [{ name: "Ventas", data: [30, 40, 35, 50] }],
      xaxis: { categories: %w[Ene Feb Mar Abr] } %>
```

## Colores: siempre del tema activo
`chart_controller.js` lee `--color-primary`/`--color-secondary`/etc. en cada render
y en cada cambio de tema. No definas `colors: [...]` a mano salvo que quieras
romper deliberadamente la consistencia con el resto del panel para ese chart.

## Por qué un `<canvas>` para resolver colores
Las variables de daisyUI son `oklch(...)` crudo, y ApexCharts asume hex/rgb en
partes de su manejo interno de color. `theme_colors.js` resuelve cualquier
color CSS a RGB vía un `<canvas>` de 1×1 — funciona para cualquier formato
válido, no solo oklch, así que si el día de mañana cambia el formato de las
variables de daisyUI esto no se rompe.

## Reactividad al cambio de tema
`theme_toggle_controller.js` dispara `window.dispatchEvent(new CustomEvent("theme:change"))`.
Cualquier chart en pantalla lo escucha y se repinta solo.

## Qué no incluye esta fase (a propósito)
- Actualización de datos en vivo desde fuera del controller (`updateSeries`) — se
  agrega cuando un caso real lo necesite (candidato: Setup 12, Dashboard).
- Un helper por tipo de chart (`line_chart_tag`, `donut_chart_tag`...) — `chart_tag`
  con `type:` cubre todos los tipos sin duplicar wrapper.
```

**docs/documentation/setup_99_TODO.md** — mueve Setup 11 a hecho, Setup 12 a CURRENT:

```markdown
* Setup 10 — Tables / Filtros / Pagy         (tabla reutilizable, filtros por allowlist)
* Setup 11 — Charts                          (wrapper ApexCharts v6.x)

## CURRENT:
* Setup 12 — Dashboard                       (demo data, claramente marcada)

## TODO:
* Setup 13 — Usuarios                        (módulo de referencia)
```

## Verificación de consistencia

Ningún chart real existe todavía fuera de `/styleguide` — Setup 12 (Dashboard) es el primer consumidor real de `chart_tag`, y no debería necesitar tocar `chart_controller.js` para nada que ApexCharts ya soporte nativamente (solo pasar las `options` correctas).

## Validaciones

```bash
bin/importmap json
# → confirma que "apexcharts" y "charts/theme_colors" están pineados

bin/dev
# → /styleguide: sección "Charts" — el line chart y el donut se ven con la
#   paleta del tema actual, no colores default de ApexCharts
# → togglé el switch de tema arriba: los dos charts cambian de color al
#   instante, sin recargar la página
# → probá con 2-3 temas distintos del selector si tenés más de dos habilitados
# → si algún color se ve "apagado" o negro, abrí la consola del navegador:
#   sería la única señal de que el truco del canvas falló para ese valor
#   (no debería pasar en Chrome/Firefox/Safari actuales, pero es la parte
#   menos probada de esta fase — avisame si ves algo raro)

bundle exec rubocop
bundle exec brakeman
```

## Seguridad

Nada de esta fase toca `params` ni datos de usuario — `series`/`options` los define el desarrollador en la vista, no llegan de un formulario. El único dato "externo" es el propio tema (cookie `theme`, ya validado en Setup 4 al solo aceptar `"dark"`/`"light"`).

## Mantenibilidad y compatibilidad futura

Setup 12 (Dashboard) usa `chart_tag` tal cual, sin tocar el wrapper — solo decide qué datos mostrar. Si algún chart futuro necesita colores fijos por serie (ej. siempre verde para "aprobado", rojo para "rechazado" sin importar el tema), se resuelve pasando `colors: [...]` en `options` — el wrapper ya lo deja pisar sin fricción porque el merge es superficial en ese nivel.