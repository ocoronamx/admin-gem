# Setup 16 — Security hardening

## Objetivo

CSP estricta, cabeceras adicionales que Rails no trae activadas por defecto, SSL forzado en producción, y confirmar que Brakeman corre limpio — dejando el terreno preparado para que Setup 17 lo enchufe a CI, sin escribir el workflow todavía (eso es explícitamente esa fase).

## De paso: Rack::Attack, ya resuelto

El ADR original (§Fase 15, y también en la propuesta de Setup 5) planeaba `Rack::Attack` para esto. Pero Setup 6 ya lo descartó explícitamente ("Verifiqué el código fuente de `ActionController::RateLimiting` — Rails 8.1 trae rate_limit nativo... una dependencia menos que mantener") — por eso el TODO actual ya no lo menciona. No hay nada que hacer acá, solo dejo constancia de por qué no aparece en esta fase pese a estar en el ADR original.

## Decisiones arquitectónicas

* **CSP estricta sin `unsafe-inline`, en vez del template comentado que trae Rails**: verifiqué que no hay un solo script/CDN externo en toda la app — Turbo/Stimulus/Tom Select/ApexCharts están vendorizados vía importmap (Setup 9/11) y Tailwind se compila local (Setup 4). Eso permite `script-src 'self'`/`style-src 'self'` sin listar dominios.
* **Nonce solo en `script-src`, no en `style-src`**: `javascript_importmap_tags` inyecta el `<script type="importmap">` inline — sin nonce, `script-src 'self'` lo bloquearía y se cae toda la app (Turbo, Stimulus, todo). Encontré el único `style=""` inline de todo el proyecto (`charts_helper.rb`, el `min-height` del contenedor del chart) y lo muevo a JS en esta misma fase — así `style-src 'self'` queda estricto sin necesitar nonce ni `unsafe-inline` para nada.
* **`style="..."` inline → `element.style.minHeight` en JS**: CSP's `style-src` bloquea el atributo HTML `style=""`, pero no la manipulación de estilos vía CSSOM (`element.style.foo = ...`) — es la forma correcta de lograr el mismo resultado visual sin debilitar la política. De paso confirma algo útil: intenté primero resolverlo con una clase de Tailwind con valor arbitrario (`min-h-[#{height}px]`), pero el compilador de Tailwind escanea archivos de forma estática — una clase armada con interpolación de Ruby en tiempo de ejecución nunca aparece "literal" en ningún archivo fuente, así que Tailwind no la generaría y el estilo simplemente no aplicaría. JS es la única opción correcta acá, no una preferencia estética.
* **`config.force_ssl = true` en producción**: estaba comentado desde que Rails generó el proyecto. Un panel admin con datos de usuarios/auditoría no debería aceptar HTTP en ningún punto — de paso, esto también marca todas las cookies (incluida la de sesión) como `secure` automáticamente, sin tener que tocar `sessions_controller.rb`.
* **`Permissions-Policy` restrictiva**: apaga cámara/micrófono/geolocalización/pagos — APIs que esta app no usa. Rails no la setea por default (a diferencia de `X-Content-Type-Options`/`Referrer-Policy`, que ya vienen con `config.load_defaults 8.1`).
* **`X-Frame-Options: DENY`** en vez del `SAMEORIGIN` default de Rails, coherente con `frame-ancestors 'none'` de la CSP — no hay ningún caso legítimo de embeber esta app en un iframe, ni del mismo origen.
* **Brakeman: confirmar que corre limpio, sin `.brakeman.yml` todavía**: agregar un archivo de ignore antes de tener un falso positivo real que justifique sería inventar complejidad. Se pin la versión de la gema, nada más.

## Alternativas consideradas

* **Gema `secure_headers`** → descartada: Rails 8 ya trae la mayoría de las cabeceras relevantes por default (`load_defaults 8.1`) y su propio DSL de CSP cubre el resto — agregar una gema para esto sería una dependencia más manteniendo algo que el framework ya resuelve.
* **`policy.script_src :self, :unsafe_inline`** (más simple, sin nonce) → descartado: es exactamente el tipo de política que no protege contra XSS, que es el motivo de tener CSP en primer lugar.
* **`.brakeman.yml` con reglas ignoradas preventivamente** → descartado, ver decisión de arriba.

## Comandos

```bash
bin/brakeman
# → confirmá 0 warnings antes de seguir; si aparece algo, se resuelve acá,
#   no se ignora para que Setup 17 lo herede
```

## Archivos

**config/initializers/content_security_policy.rb** (reemplaza el template comentado):

```ruby
# Nada se carga desde un CDN externo en este proyecto — Turbo/Stimulus, Tom
# Select y ApexCharts están vendorizados vía importmap (Setup 9/11), y
# Tailwind se compila localmente (Setup 4). Eso permite una política
# estricta, sin tener que listar dominios de terceros.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.font_src        :self
    policy.img_src         :self, :data
    policy.object_src      :none
    policy.script_src      :self
    policy.style_src       :self
    policy.connect_src     :self
    policy.base_uri        :none
    policy.frame_ancestors :none
  end

  # El importmap de Rails inyecta <script type="importmap"> y el bootstrap
  # de módulos como scripts inline — sin nonce, script-src :self los
  # bloquearía y se cae toda la app. No hace falta nonce en style-src: el
  # único style="" inline que había (charts_helper.rb) se movió a JS en esta
  # misma fase — ver app/javascript/controllers/chart_controller.js.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
```

**config/application.rb** — agrega dentro de `class Application`:

```ruby
    # Cabeceras de defensa adicional. X-Frame-Options/frame-ancestors (CSP)
    # se solapan a propósito — DENY cubre navegadores que no respeten
    # frame-ancestors. Permissions-Policy apaga APIs del navegador que esta
    # app no usa.
    config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"
    config.action_dispatch.default_headers["Permissions-Policy"] =
      "camera=(), microphone=(), geolocation=(), payment=()"
```

**config/environments/production.rb** — descomenta:

```ruby
  config.force_ssl = true
```

**Gemfile** — pin de versión:

```ruby
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 8.0", require: false
```

**app/helpers/charts_helper.rb** — saca el `style=""` inline:

```ruby
  def chart_tag(type:, series:, id: nil, height: 320, **options)
    content_tag :div, "",
      id: id,
      class: "w-full",
      data: {
        controller: "chart",
        chart_type_value: type.to_s,
        chart_series_value: series,
        chart_options_value: options,
        chart_height_value: height
      }
  end
```

**app/javascript/controllers/chart_controller.js** — agrega el value y setealo en JS:

```javascript
  static values = { type: String, series: Array, options: Object, height: Number }

  connect() {
    this.element.style.minHeight = `${this.heightValue}px`
    this.chart = new ApexCharts(this.element, this.buildOptions())
    this.chart.render()

    this.onThemeChange = () => this.chart.updateOptions(this.buildOptions())
    window.addEventListener("theme:change", this.onThemeChange)
  }
```

**spec/requests/security_headers_spec.rb** (nuevo):

```bash
touch spec/requests/security_headers_spec.rb
```

```ruby
require "rails_helper"

RSpec.describe "Security headers", type: :request do
  it "envía una Content-Security-Policy estricta" do
    get root_path

    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("default-src 'self'")
    expect(csp).to include("frame-ancestors 'none'")
    expect(csp).not_to include("unsafe-inline")
  end

  it "deniega el framing con X-Frame-Options" do
    get root_path
    expect(response.headers["X-Frame-Options"]).to eq("DENY")
  end
end
```

**docs/documentation/setup_99_TODO.md** — mueve Setup 16 a hecho, Setup 17 a CURRENT:

```markdown
* Setup 15 — Testing                         (RSpec, factories, qué probar y qué no)
* Setup 16 — Security hardening              (CSP, headers, Brakeman)

## CURRENT:
* Setup 17 — CI/CD                           (GitHub Actions: lint → security → tests → build)
```

## Verificación de consistencia

Ningún cambio de esta fase toca lógica de negocio — son config + un helper que pasó de inline-style a JS. `chart_tag` mantiene exactamente la misma firma (`height:` sigue siendo un kwarg normal); ningún caller (`dashboard/index.html.erb`, `pages/styleguide.html.erb`) necesita cambios.

## Validaciones

```bash
bin/brakeman
bundle exec rspec
bundle exec rubocop

bin/dev
# → abrí devtools → Network → cualquier request → confirmá el header
#   Content-Security-Policy en la respuesta, sin "unsafe-inline"
# → confirmá que Turbo/Stimulus siguen funcionando (navegación, toggle de
#   tema, modal, Tom Select) — si el nonce del importmap no calzara, la
#   consola tiraría errores de CSP y la app se vería "rota" (sin JS)
# → /styleguide y /dashboard: los charts siguen con su altura mínima
#   correcta, ahora seteada por chart_controller.js en vez de style=""
# → en producción (o RAILS_ENV=production local): confirmá que http:// 
#   redirige a https:// y que la cookie de sesión sale con el flag Secure
```

## Seguridad

Es literalmente el contenido de esta fase — pero vale nombrar el patrón: la CSP no es la primera línea de defensa (eso son las validaciones/Pundit/params permitidos de las fases anteriores), es la última — si algo se coló y logró inyectar un `<script>`, la CSP igual lo bloquea en el navegador. Por eso vale la pena que sea estricta de verdad y no una versión con `unsafe-inline` "por las dudas".

## Mantenibilidad y compatibilidad futura

Si algún módulo futuro necesita Action Cable/Turbo Streams (actualización en vivo del dashboard, por ejemplo), `connect-src 'self'` va a necesitar sumar `ws://`/`wss://` explícitamente — la CSP de esta fase no lo previó porque hoy no hay ningún uso de WebSockets en la app. Setup 17 (CI/CD) hereda un `bin/brakeman` limpio para simplemente enchufarlo al pipeline, sin tener que resolver warnings a esa altura.

## Corrección (post-implementación)

`style-src 'self'` sin excepciones rompía la leyenda de ApexCharts — la
librería inyecta un `<style>` inline por render (confirmado en consola de
Chrome, no es código propio). Se relajó a `style-src 'self' 'unsafe_inline'`.
`script-src` no se tocó. Ver commit de fix para el detalle.

Encontrado — y es un hueco real de Setup 16, no algo que hicieras vos. La consola lo deja clarísimo:

```
Applying inline style violates ... 'style-src 'self''... blocked.
appendToForeignObject @ apexcharts-...js
```

ApexCharts arma su leyenda usando un `<foreignObject>` dentro del SVG (para poder usar flexbox de HTML normal ahí adentro) e inyecta su propio `<style>` inline con la CSS de esa leyenda cada vez que renderiza. Eso es interno de la librería, no algo que yo escribí — y mi CSP de Setup 16 lo bloquea sin excepción, así que la leyenda queda sin ningún estilo: los círculos de color y el texto pierden su `display: flex`/tamaño/posicionamiento y terminan apilados y estirados a lo loco — eso es exactamente el círculo negro gigante que ves tapando "Editor".

## Por qué no lo agarré en Setup 16

Cuando audité los `style=""` inline, busqué en **mi propio código** (`grep`) y encontré uno solo (`charts_helper.rb`), que arreglé moviéndolo a JS. No consideré que una librería de terceros pudiera inyectar `<style>` por su cuenta en tiempo de ejecución — ese bug no aparece haciendo grep del código fuente, solo se ve renderizando de verdad en el navegador. Buen catch.

## El fix

La consola te da hasta el hash SHA-256 exacto de cada bloque bloqueado — en teoría podría permitir *solo esos hashes* en vez de relajar la política entera. Lo descarté: son del bundle minificado de ApexCharts, así que cualquier actualización de la librería cambia el minificado y por lo tanto el hash, rompiendo los charts silenciosamente hasta que alguien mire la consola de nuevo — cambiar de versión no debería romper la CSP. La leyenda se regenera así en cada render de cada chart, con contenido que no controlamos nosotros ni es estático entre versiones.

Lo pragmático: `style-src` con `unsafe-inline`, dejando `script-src` tan estricto como estaba (ahí sí importa — inyección de script es mucho más grave que de estilo, y ahí no hay ningún tercero que lo necesite).

**config/initializers/content_security_policy.rb** — cambia solo esta línea:

```ruby
    # ApexCharts arma su leyenda con un <foreignObject> dentro del SVG e
    # inyecta su propio <style> inline en cada render (confirmado en consola,
    # no es código nuestro) — no hay forma de noncear/hashear eso sin que se
    # rompa en cada actualización de la librería. script-src se queda estricto:
    # ahí sí importa, no hay ningún tercero que necesite inline.
    policy.style_src :self, :unsafe_inline
```

De paso, la otra línea de la consola (no relacionada al CSP, solo una advertencia de performance):

```
Canvas2D: Multiple readback operations using getImageData are faster with willReadFrequently
```

**app/javascript/charts/theme_colors.js** — un solo cambio, en la creación del contexto:

```javascript
const ctx = canvas.getContext("2d", { willReadFrequently: true })
```

## Validaciones

```bash
bin/dev
# → /styleguide: la leyenda de los dos charts se ve normal, sin el círculo
#   negro ni el layout roto
# → devtools console: sin errores de CSP, sin el warning de Canvas2D
# → probá el toggle de tema — los charts se siguen repintando igual que antes
```

Una alternativa que descarté pero que existe si en algún momento te importa más la estrictez que la simplicidad: scopear `content_security_policy` por controlador (Rails lo permite — un bloque distinto solo en los controllers que rendericen charts) en vez de relajar site-wide. No lo hice porque agrega una capa de "¿esta página tiene CSP distinta y por qué?" para un riesgo (inyección de *estilo*, no de script) que ya es bajo de por sí.