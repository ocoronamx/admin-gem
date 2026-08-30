# Setup: Frontend / Design System

## Objetivo

Instalar DaisyUI v5 sobre Tailwind v4 sin Node, definir los tokens de marca (colores, tipografía, radios, bordes, profundidad) en un solo archivo, resolver el cambio claro/oscuro sin parpadeo, y dejar una página interna /styleguide que sirva de documentación viva. No construimos sidebar/header todavía — eso es la 

## Decisiones arquitectónicas

DaisyUI sin npm: el método "no-Node" oficial de DaisyUI consiste en descargar dos archivos .mjs (el plugin y un módulo aparte solo para temas personalizados) como release assets de GitHub, y referenciarlos como plugins locales de Tailwind v4.
Verifiqué que existen y pesan ~340 KB + ~45 KB — se ejecutan únicamente durante el build de Tailwind (nunca llegan al navegador; lo que se sirve es el CSS ya compilado).

Sobreescribimos los temas built-in light/dark en vez de crear temas con nombre propio. 
Así el theme-controller nativo de DaisyUI (un <input type="checkbox">, cero JS de terceros) funciona sin fricción, y data-theme="light"/"dark" sigue siendo válido si algún día consultas la documentación de DaisyUI.

Persistencia del tema vía cookie, no localStorage: una cookie la puede leer Rails antes de renderizar el layout (cero parpadeo). localStorage solo existe después de que el HTML ya se pintó.
Tipografía = pila de fuentes del sistema (no una web font).
Cero peticiones de red, cero archivo que mantener. Un rebranding futuro que sí quiera una fuente propia cambia una sola línea (documentado abajo).

## Alternativas consideradas

* Self-host de Inter/otra fuente → descartado por ahora (sin beneficio medible en un boilerplate genérico; se añade el día que un cliente concreto lo pida).
* daisyui_on_phlex / daisy_components (gemas que envuelven DaisyUI en componentes Phlex) → descartadas: introducirían una segunda capa de componentes redundante con la decisión ya tomada (partials + helpers), y son proyectos pequeños (pocos miles de descargas) para apostar un boilerplate de años a ellos.
* Tag latest de GitHub para los .mjs → descartado en favor de una versión fijada (v5.7.22), para que el build sea reproducible y las actualizaciones sean un cambio deliberado, no accidental.

### Qué prevenimos
FOUC (flash del tema equivocado al cargar).
Que rebrandear implique tocar vistas — todo pasa por ~25 variables en un solo CSS.
Descargar sin darnos cuenta una versión distinta de DaisyUI en cada bin/setup de un desarrollador nuevo.
Ruido de estilos: nada de clases arbitrarias de Tailwind dispersas para "arreglar" un color — si algo se repite, es un token.

### Comandos

```bash
curl -sL -o app/assets/tailwind/daisyui.mjs \
  "https://github.com/saadeghi/daisyui/releases/download/v5.7.22/daisyui.mjs"

curl -sL -o app/assets/tailwind/daisyui-theme.mjs \
  "https://github.com/saadeghi/daisyui/releases/download/v5.7.22/daisyui-theme.mjs"
```

### Archivos

app/assets/tailwind/application.css (reemplaza el contenido generado por rails new):

```css
@import "tailwindcss";

/* Los .mjs son plugins de build, no plantillas: que Tailwind no los escanee */
@source not "./daisyui{,*}.mjs";

@plugin "./daisyui.mjs" {
  themes: light --default, dark --prefersdark;
}

/*
 * ============================================================
 * TOKENS DE MARCA — único lugar que se toca para rebrandear
 * el sistema completo. Ver docs/design-system.md.
 * ============================================================
 */
@theme {
  /* Cambiar esta línea es todo lo que hace falta para pasar a
     una fuente de marca propia (self-hosted) en el futuro. */
  --font-sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto,
    "Helvetica Neue", Arial, sans-serif;
}

/* Tema claro (sobreescribe el "light" incluido en DaisyUI) */
@plugin "./daisyui-theme.mjs" {
  name: "light";
  default: true;
  prefersdark: false;
  color-scheme: light;

  --color-base-100: oklch(100% 0 0);
  --color-base-200: oklch(97% 0.002 247);
  --color-base-300: oklch(92% 0.004 247);
  --color-base-content: oklch(21% 0.006 285);

  --color-primary: oklch(45% 0.15 264);
  --color-primary-content: oklch(97% 0.01 264);
  --color-secondary: oklch(55% 0.04 255);
  --color-secondary-content: oklch(98% 0.01 255);
  --color-accent: oklch(70% 0.14 200);
  --color-accent-content: oklch(20% 0.05 200);
  --color-neutral: oklch(30% 0.01 260);
  --color-neutral-content: oklch(96% 0.005 260);

  --color-info: oklch(65% 0.15 235);
  --color-info-content: oklch(98% 0.01 235);
  --color-success: oklch(62% 0.15 155);
  --color-success-content: oklch(98% 0.02 155);
  --color-warning: oklch(80% 0.15 85);
  --color-warning-content: oklch(25% 0.05 85);
  --color-error: oklch(60% 0.22 25);
  --color-error-content: oklch(98% 0.02 25);

  /* Look sobrio/empresarial: radios modestos, sombra sutil, sin textura */
  --radius-selector: 0.375rem;
  --radius-field: 0.5rem;
  --radius-box: 0.75rem;
  --size-selector: 0.25rem;
  --size-field: 0.25rem;
  --border: 1px;
  --depth: 1;
  --noise: 0;
}

/* Tema oscuro (sobreescribe el "dark" incluido en DaisyUI) */
@plugin "./daisyui-theme.mjs" {
  name: "dark";
  default: false;
  prefersdark: true;
  color-scheme: dark;

  --color-base-100: oklch(19% 0.006 285);
  --color-base-200: oklch(23% 0.006 285);
  --color-base-300: oklch(28% 0.007 285);
  --color-base-content: oklch(93% 0.004 260);

  --color-primary: oklch(70% 0.14 264);
  --color-primary-content: oklch(20% 0.05 264);
  --color-secondary: oklch(70% 0.03 255);
  --color-secondary-content: oklch(20% 0.02 255);
  --color-accent: oklch(75% 0.13 200);
  --color-accent-content: oklch(20% 0.05 200);
  --color-neutral: oklch(85% 0.005 260);
  --color-neutral-content: oklch(20% 0.01 260);

  --color-info: oklch(72% 0.14 235);
  --color-info-content: oklch(20% 0.05 235);
  --color-success: oklch(70% 0.15 155);
  --color-success-content: oklch(20% 0.05 155);
  --color-warning: oklch(80% 0.15 85);
  --color-warning-content: oklch(25% 0.05 85);
  --color-error: oklch(68% 0.2 25);
  --color-error-content: oklch(20% 0.05 25);

  --radius-selector: 0.375rem;
  --radius-field: 0.5rem;
  --radius-box: 0.75rem;
  --size-selector: 0.25rem;
  --size-field: 0.25rem;
  --border: 1px;
  --depth: 1;
  --noise: 0;
}
```

app/controllers/application_controller.rb — lectura del tema desde cookie:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_theme

  helper_method :current_theme

  private

  def set_theme
    @current_theme = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
  end

  def current_theme
    @current_theme
  end
end
```

app/javascript/controllers/theme_toggle_controller.js (nuevo — regístralo en app/javascript/controllers/index.js como haces con cualquier controller de Stimulus):

```bash
rails generate stimulus theme_toggle
```

```javascript
import { Controller } from "@hotwired/stimulus"

// Persiste la preferencia de tema en una cookie legible por Rails,
// y actualiza data-theme al instante (sin esperar al próximo request).
export default class extends Controller {
  persist(event) {
    const theme = event.target.checked ? "dark" : "light"
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-theme", theme)
  }
}
```

app/views/layouts/application.html.erb — ajusta la etiqueta <html>:

```erb
<!DOCTYPE html>
<html data-theme="<%= current_theme %>">
  <head>
    ...
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

app/controllers/pages_controller.rb (nuevo — página de verificación, no producción):

```bash
bin/rails generate controller Pages styleguide
```

```ruby
class PagesController < ApplicationController
  before_action :ensure_local_environment, only: :styleguide

  def styleguide
  end

  private

  def ensure_local_environment
    head :not_found unless Rails.env.local?
  end
end
```

config/routes.rb — añade:

```ruby
get "styleguide", to: "pages#styleguide"
root to: "pages#styleguide" # temporal — la Fase 5 lo reemplaza por login/dashboard
```

app/views/pages/styleguide.html.erb (nuevo — resumen, el archivo completo lo verás corriendo bin/dev):

```erb
<div class="p-8 space-y-8 bg-base-200 min-h-screen">
  <div class="flex items-center justify-between">
    <h1 class="text-2xl font-semibold text-base-content">Design System — admin-gem</h1>
    <label class="flex items-center gap-2 cursor-pointer">
      <span class="text-sm">Modo oscuro</span>
      <input type="checkbox" value="dark" class="toggle theme-controller"
             data-controller="theme-toggle" data-action="change->theme-toggle#persist"
             <%= "checked" if current_theme == "dark" %> />
    </label>
  </div>

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Colores semánticos</h2>
    <div class="flex flex-wrap gap-2">
      <span class="badge badge-primary">primary</span>
      <span class="badge badge-secondary">secondary</span>
      <span class="badge badge-accent">accent</span>
      <span class="badge badge-neutral">neutral</span>
      <span class="badge badge-info">info</span>
      <span class="badge badge-success">success</span>
      <span class="badge badge-warning">warning</span>
      <span class="badge badge-error">error</span>
    </div>
  </section>

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Botones</h2>
    <div class="flex flex-wrap gap-2">
      <button class="btn btn-primary">Guardar</button>
      <button class="btn btn-secondary">Secundario</button>
      <button class="btn btn-outline">Outline</button>
      <button class="btn btn-error">Eliminar</button>
      <button class="btn" disabled>Deshabilitado</button>
    </div>
  </section>
</div>
```

docs/design-system.md (nuevo — documenta la estrategia de rebranding pedida en el ADR):

```bash
touch docs/design-system.md
```

```markdown
# Design System — admin-gem

Todo el look del sistema vive en `app/assets/tailwind/application.css`,
dentro de los dos bloques `@plugin "./daisyui-theme.mjs" { name: "light"/"dark"; ... }`.

## Para rebrandear completamente el sistema
1. Cambia los valores `--color-primary`, `--color-secondary`, `--color-accent`
   (formato OKLCH recomendado) en ambos bloques de tema.
2. Ajusta `--radius-field`/`--radius-box` si la marca pide esquinas más
   rectas o más redondeadas.
3. Corre `bin/dev` y revisa `/styleguide` — no hace falta tocar ninguna vista.

## Para usar una fuente de marca propia
Reemplaza el valor de `--font-sans` en el bloque `@theme` por la fuente
autoalojada (agrégala como asset y un `@font-face` antes del `@theme`).

## Actualizar DaisyUI
Repite los comandos `curl` de la Fase 3 con la nueva versión, revisa el
[changelog](https://daisyui.com/docs/changelog/) por cambios de nombres de
clases, y corre `bin/dev` para confirmar que `/styleguide` se sigue viendo bien.
```

## Verificación de consistencia

app/assets/tailwind/daisyui.mjs y daisyui-theme.mjs sí se commitean a git (son código vendored, no un build artifact — no van en .gitignore).
Lo que sí sigue ignorado es app/assets/builds/tailwind.css (se regenera en cada build).

## Validaciones

```bash
bin/dev
# → abre http://localhost:3000/styleguide
# → confirma: colores sobrios, botones con el radio correcto, el toggle
#   cambia a oscuro sin parpadeo y sin recargar la página
bundle exec rubocop
```

## Seguridad

La cookie theme no lleva datos sensibles (solo "light"/"dark"), se valida contra una lista blanca en set_theme antes de usarla (nunca se interpola un valor arbitrario del usuario en data-theme),
y /styleguide devuelve 404 fuera de development/test — no expone nada en producción.

## Mantenibilidad y compatibilidad futura

Cuando alguien pregunte "¿dónde cambio el azul de la marca?", la respuesta es un archivo y dos bloques.
/styleguide queda como referencia viva para cualquier desarrollador nuevo, y se irá ampliando con cada componente que construyamos en la Fase 7.