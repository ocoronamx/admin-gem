# Setup 8 — Componentes

## Objetivo

Construir la librería de componentes visuales reutilizables que van a consumir todos los módulos futuros (Setup 9 en adelante): botones, cards, alertas, empty states, modales, y diálogos de confirmación. 
Cierra el Design System que empezamos en Setup 4.

## Decisiones arquitectónicas

* Tres patrones distintos, según la forma del contenido (ya lo anticipaba la tabla del ADR §9, ahora con ejemplos concretos): partial con locals para valores simples (render "components/button", text: "Guardar"), partial como layout con yield cuando el contenido interno es HTML libre (render(layout: "components/card") { ... }), y helper de una línea cuando no hace falta ni eso (status_badge(...)).
* Badge NO es un partial. Es un <span> con una clase — envolverlo sería exactamente la "componentización excesiva" que el ADR pidió evitar. Queda como helper.
* Diálogos de confirmación vía Turbo nativo, no un modal hecho a mano por cada botón. Verifiqué el código fuente de Turbo: Turbo.config.forms.confirm es una función sobreescribible (mensaje, form, submitter) => Promise<boolean> — la reemplazamos una sola vez por un modal con nuestros tokens, y cualquier botón/link con data: { turbo_confirm: "..." } en el futuro (Setup 10, "Eliminar") lo usa automáticamente, sin código adicional por cada caso.
* Modal sobre <dialog> nativo de HTML, no un div+overlay hecho a mano — accesibilidad (foco, Esc, backdrop)gratis del navegador.

## Alternativas consideradas

* Toast, Tabs, Dropdown genérico → deliberadamente no incluidos todavía.
Generalizar con un solo caso de uso real es adivinar la forma que van a necesitar; se extraen cuando aparezca un segundo caso concreto.
* confirm() nativo del navegador para acciones destructivas → descartado, no respeta el tema oscuro ni la identidad visual del sistema (justo lo que Turbo 8 permite reemplazar).

## Qué prevenimos

Cada módulo futuro reinventando su propio botón/card/alerta con clases de Tailwind sueltas.
Un confirm() gris del navegador rompiendo la experiencia "premium" en medio de un flujo administrativo.
Partial explosion: componentes tan triviales que abrir el archivo cuesta más que leer el HTML inline.

## Archivos

app/helpers/icons_helper.rb — añade estas entradas al hash ICONS (todo lo demás queda igual):

```ruby
    check_circle: '<path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />',
    exclamation_triangle: '<path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />',
    x_circle: '<path stroke-linecap="round" stroke-linejoin="round" d="m9.75 9.75 4.5 4.5m0-4.5-4.5 4.5M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />',
    information_circle: '<path stroke-linecap="round" stroke-linejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />',
    trash: '<path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />',
```

app/views/components/_button.html.erb (nuevo):

```bash
mkdir app/views/components
touch app/views/components/_button.html.erb
```

```erb
<%
  text        = local_assigns.fetch(:text)
  variant     = local_assigns.fetch(:variant, :primary)
  size        = local_assigns.fetch(:size, :md)
  href        = local_assigns[:href]
  method      = local_assigns[:method]
  confirm     = local_assigns[:confirm]
  disabled    = local_assigns.fetch(:disabled, false)
  loading     = local_assigns.fetch(:loading, false)
  icon_name   = local_assigns[:icon]
  extra_class = local_assigns.fetch(:class, "")
  type        = local_assigns.fetch(:type, "button")

  variant_class = {
    primary: "btn-primary", secondary: "btn-secondary", outline: "btn-outline",
    ghost: "btn-ghost", error: "btn-error", neutral: "btn-neutral"
  }.fetch(variant.to_sym, "btn-primary")

  size_class = { sm: "btn-sm", md: "", lg: "btn-lg" }.fetch(size.to_sym, "")
  classes = ["btn", variant_class, size_class, extra_class].reject(&:blank?).join(" ")
%>

<% if href %>
  <%= link_to href, class: classes, data: { turbo_method: method, turbo_confirm: confirm }.compact do %>
    <% if loading %>
      <span class="loading loading-spinner loading-sm"></span>
    <% elsif icon_name %>
      <%= icon(icon_name, css_class: "size-4") %>
    <% end %>
    <%= text %>
  <% end %>
<% else %>
  <button type="<%= type %>" class="<%= classes %>" <%= "disabled" if disabled || loading %>>
    <% if loading %>
      <span class="loading loading-spinner loading-sm"></span>
    <% elsif icon_name %>
      <%= icon(icon_name, css_class: "size-4") %>
    <% end %>
    <%= text %>
  </button>
<% end %>
```

app/views/components/_card.html.erb (nuevo — se usa con render layout:, ver ejemplo en el styleguide):

```bash
touch app/views/components/_card.html.erb
```

```erb
<%
  title       = local_assigns[:title]
  actions     = local_assigns[:actions]
  extra_class = local_assigns.fetch(:class, "")
%>
<div class="card bg-base-100 shadow <%= extra_class %>">
  <div class="card-body">
    <% if title || actions %>
      <div class="flex items-center justify-between mb-2">
        <% if title %><h2 class="card-title"><%= title %></h2><% end %>
        <% if actions %><div class="flex gap-2"><%= actions %></div><% end %>
      </div>
    <% end %>
    <%= yield %>
  </div>
</div>
```

app/views/components/_alert.html.erb (nuevo):

```bash
touch app/views/components/_alert.html.erb
```

```erb
<%
  variant     = local_assigns.fetch(:variant, :info)
  message     = local_assigns.fetch(:message)
  dismissible = local_assigns.fetch(:dismissible, false)
  extra_class = local_assigns.fetch(:class, "")

  variant_class = {
    info: "alert-info", success: "alert-success", warning: "alert-warning", error: "alert-error"
  }.fetch(variant.to_sym, "alert-info")

  icon_name = {
    info: :information_circle, success: :check_circle, warning: :exclamation_triangle, error: :x_circle
  }.fetch(variant.to_sym, :information_circle)

  html_attrs = { class: "alert #{variant_class} shadow-sm #{extra_class}".strip, role: "alert" }
  html_attrs[:data] = { controller: "alert" } if dismissible
%>
<%= tag.div(**html_attrs) do %>
  <%= icon(icon_name, css_class: "size-5 shrink-0") %>
  <span><%= message %></span>
  <% if dismissible %>
    <button type="button" class="btn btn-ghost btn-xs btn-circle ml-auto"
            data-action="alert#dismiss" aria-label="Cerrar">
      <%= icon(:x_mark, css_class: "size-4") %>
    </button>
  <% end %>
<% end %>
```

app/views/components/_empty_state.html.erb (nuevo):

```bash
touch app/views/components/_empty_state.html.erb
```

```erb
<%
  title       = local_assigns.fetch(:title)
  description = local_assigns[:description]
  icon_name   = local_assigns.fetch(:icon, :squares_2x2)
  action_text = local_assigns[:action_text]
  action_href = local_assigns[:action_href]
%>
<div class="flex flex-col items-center justify-center text-center py-16 px-4">
  <div class="rounded-full bg-base-200 p-4 mb-4">
    <%= icon(icon_name, css_class: "size-8 text-base-content/40") %>
  </div>
  <h3 class="font-medium text-base-content mb-1"><%= title %></h3>
  <% if description %>
    <p class="text-sm text-base-content/60 max-w-sm mb-4"><%= description %></p>
  <% end %>
  <% if action_text && action_href %>
    <%= render "components/button", text: action_text, href: action_href, variant: :primary %>
  <% end %>
</div>
```

app/views/components/_modal.html.erb (nuevo — se usa con render layout:):

```bash
touch app/views/components/_modal.html.erb
```

```erb
<%
  id    = local_assigns.fetch(:id)
  title = local_assigns[:title]
%>
<dialog id="<%= id %>" class="modal">
  <div class="modal-box">
    <% if title %>
      <h3 class="text-lg font-semibold mb-4"><%= title %></h3>
    <% end %>
    <%= yield %>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>cerrar</button>
  </form>
</dialog>
```

app/helpers/badge_helper.rb (nuevo):

```bash
touch app/helpers/badge_helper.rb
```

```ruby
module BadgeHelper
  # Ej: status_badge("Activo", variant: :success)
  def status_badge(label, variant:)
    content_tag(:span, label, class: "badge badge-#{variant}")
  end
end
```

app/helpers/application_helper.rb — reemplaza flash_alert_class por esto (ahora devuelve el variant: que espera el componente, no una clase CSS):

```ruby
module ApplicationHelper
  def flash_alert_variant(type)
    { "notice" => :info, "success" => :success, "alert" => :error, "error" => :error, "warning" => :warning }
      .fetch(type.to_s, :info)
  end
end
```

app/views/layouts/_flash.html.erb (reemplaza — ahora usa el componente de alerta):

```erb
<% flash.each do |type, message| %>
  <%= render "components/alert", variant: flash_alert_variant(type), message: message, dismissible: true, class: "mb-4" %>
<% end %>
```

app/javascript/controllers/alert_controller.js (nuevo):

```bash
touch app/javascript/controllers/alert_controller.js
```

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
```

app/javascript/controllers/modal_controller.js (nuevo):

```bash
touch app/javascript/controllers/modal_controller.js
```

```javascript
import { Controller } from "@hotwired/stimulus"

// Uso: <button data-controller="modal" data-modal-id-value="mi_modal" data-action="modal#open">Abrir</button>
export default class extends Controller {
  static values = { id: String }

  open() {
    document.getElementById(this.idValue)?.showModal()
  }
}
```

app/javascript/turbo_confirm.js (nuevo — reemplaza el confirm() feo del navegador en todo data-turbo-confirm de la app):

```bash
touch app/javascript/turbo_confirm.js
```

```javascript
import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message, formElement, submitter) => {
  const dialog = document.getElementById("turbo_confirm_dialog")
  dialog.querySelector("[data-turbo-confirm-message]").textContent = message
  dialog.showModal()

  return new Promise((resolve) => {
    const acceptBtn = dialog.querySelector("[data-turbo-confirm-accept]")
    const cancelBtn = dialog.querySelector("[data-turbo-confirm-cancel]")

    const cleanup = (result) => {
      dialog.close()
      acceptBtn.removeEventListener("click", onAccept)
      cancelBtn.removeEventListener("click", onCancel)
      resolve(result)
    }
    const onAccept = () => cleanup(true)
    const onCancel = () => cleanup(false)

    acceptBtn.addEventListener("click", onAccept, { once: true })
    cancelBtn.addEventListener("click", onCancel, { once: true })
  })
}
```

config/importmap.rb — añade:

```ruby
pin "turbo_confirm"
```

app/javascript/application.js — añade junto a los demás import:

```javascript
import "turbo_confirm"
```

app/views/layouts/admin.html.erb — añade el diálogo global justo antes de </body> (una sola vez, disponible en toda la app):

```erb
      <dialog id="turbo_confirm_dialog" class="modal">
        <div class="modal-box">
          <h3 class="text-lg font-semibold mb-2">Confirmar acción</h3>
          <p class="text-base-content/70 mb-6" data-turbo-confirm-message></p>
          <div class="modal-action">
            <button type="button" class="btn" data-turbo-confirm-cancel>Cancelar</button>
            <button type="button" class="btn btn-error" data-turbo-confirm-accept>Confirmar</button>
          </div>
        </div>
      </dialog>
    </div>
  </body>
</html>
```

app/views/pages/styleguide.html.erb — añade estas secciones (después de "Iconos disponibles"):

```erb
  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Card (render layout:, contenido libre)</h2>
    <%= render(layout: "components/card", locals: { title: "Ejemplo" }) do %>
      <p class="text-base-content/70">Este contenido viene de un bloque, no de un local.</p>
    <% end %>
  </section>

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Alertas</h2>
    <%= render "components/alert", variant: :info, message: "Esto es información." %>
    <%= render "components/alert", variant: :success, message: "La operación fue exitosa." %>
    <%= render "components/alert", variant: :warning, message: "Revisa esto antes de continuar." %>
    <%= render "components/alert", variant: :error, message: "Algo salió mal.", dismissible: true %>
  </section>

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Badges de estado (helper, no partial)</h2>
    <div class="flex gap-2">
      <%= status_badge("Activo", variant: :success) %>
      <%= status_badge("Inactivo", variant: :neutral) %>
    </div>
  </section>

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Empty state</h2>
    <%= render "components/empty_state", title: "Sin catálogos todavía",
          description: "Cuando exista el módulo, aquí se listarán.", icon: :squares_2x2 %>
  </section>

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Modal</h2>
    <button class="btn" data-controller="modal" data-modal-id-value="demo_modal" data-action="modal#open">
      Abrir modal
    </button>
    <p class="text-xs text-base-content/50 mt-2">
      Los diálogos de confirmación (<code>data: { turbo_confirm: "..." }</code>) usan el mismo
      mecanismo de <code>&lt;dialog&gt;</code> — se verán en acción en Setup 10 con "Eliminar".
    </p>
  </section>

  <%= render(layout: "components/modal", locals: { id: "demo_modal", title: "Modal de ejemplo" }) do %>
    <p class="text-base-content/70 mb-4">Contenido del modal, definido con un bloque igual que Card.</p>
    <div class="modal-action">
      <form method="dialog"><button class="btn">Cerrar</button></form>
    </div>
  <% end %>
```

docs/conventions/components.md (nuevo):

```bash
touch docs/conventions/components.md
```

```markdown
# Convenciones de componentes — admin-gem

| Necesitas | Patrón | Ejemplo |
|---|---|---|
| Un texto/valor simple como parámetro | Partial con locals | `render "components/button", text: "Guardar", variant: :primary` |
| Contenido HTML libre adentro | Partial como layout (yield) | `render(layout: "components/card", locals: { title: "..." }) { ... }` |
| Una decisión de una línea sin marcado propio | Helper | `status_badge("Activo", variant: :success)` |
| Interactividad en el navegador | Stimulus controller | `data-controller="modal"` |

## Componentes disponibles
- `components/_button`, `components/_card`, `components/_alert`, `components/_empty_state`, `components/_modal`
- Confirmación destructiva: `data: { turbo_method: :delete, turbo_confirm: "..." }` en cualquier link/botón

## Deliberadamente no incluidos todavía
Tabs, Toast, Dropdown genérico — se extraen cuando aparezca un **segundo** caso de uso
real. Antes de eso, generalizar es adivinar la forma que van a necesitar.
```

## Verificación y validaciones

```bash
bin/dev
# → /styleguide: cards, alertas de los 4 colores (la de error se puede cerrar con la X),
#   badges, empty state, y el botón "Abrir modal" funcionando
# → prueba el modo oscuro: todos los componentes nuevos respetan los tokens sin cambios
bundle exec rubocop
bundle exec brakeman
```

## Seguridad, mantenibilidad y futuro

El diálogo de confirmación reemplaza window.confirm() en toda la app con un solo archivo (turbo_confirm.js) — cuando Setup 10 agregue "Eliminar" a la tabla de Usuarios, ya funciona sin escribir una línea de JS adicional.
docs/conventions/components.md responde de antemano la pregunta que evita el debate de "¿esto va en un partial o un helper?" cada vez que se agregue un componente nuevo.