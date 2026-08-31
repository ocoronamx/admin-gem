# Setup 9 — Forms

## Objetivo

Form builder por defecto (AdminFormBuilder) que envuelve cada campo en el markup de DaisyUI v5 (fieldset + label + input + validator-hint), Tom Select para selects enriquecidos, e inputs nativos de fecha — tal como quedó decidido en el ADR §3.4/§8.
Dogfoodea el builder en los tres formularios que ya existen (sessions, passwords) en vez de dejarlos con el markup viejo.

### De paso: bug en PasswordsController

Revisando el wiring de Pundit de Setup 7 antes de tocar sus vistas: PasswordsController es el único controlador que no está en skip_pundit_authorization? (que solo mira "sessions") ni tiene el skip_after_action explícito que sí tiene PagesController.
Ahora mismo, visitar /passwords/new o /passwords/edit revienta con Pundit::AuthorizationNotPerformedError (no rescatado — el rescue_from solo cubre NotAuthorizedError). Lo incluyo en "Archivos" porque si no, no vas a poder verificar visualmente el formulario nuevo de passwords.

## Decisiones arquitectónicas

* DaisyUI v5 real, no v4: verifiqué el upgrade guide de daisyUI — form-control se eliminó (reemplazado por fieldset/label planos) e input-bordered ya no hace falta (input trae borde por defecto en v5). Las vistas de Setup 6 quedaron escritas con sintaxis v4 aunque el paquete instalado es v5; esta fase las corrige de paso.
* validator + validator-hint de DaisyUI en vez de JS de validación propio: colorean el campo según las reglas HTML5 nativas (required, pattern, minlength, type="email") sin una sola línea de JS. El mismo elemento validator-hint muestra el error del servidor (object.errors) cuando existe — un solo mecanismo visual para los dos casos, con el error del servidor teniendo prioridad.
* tom-select-rails (~> 2.5), no un pin manual a CDN: tal como fijaste en el ADR. Se integra al asset pipeline exactamente igual que turbo-rails/stimulus-rails (ya en tu Gemfile) — sin red en build time, sin package.json.
* CSS de Tom Select escrito a mano con tus tokens, no el theme oficial de la gema: el theme por defecto de Tom Select trae colores fijos que no responden a --color-* ni a dark/light. Es el mismo criterio que ya usaste en Setup 4 (tokens únicos) y Setup 8 (nada de temas de terceros sin adaptar).
* Progresivo por diseño: tom_select no oculta el <select> original con CSS de antemano — Tom Select lo oculta él mismo al inicializar. Si el JS falla, el campo sigue siendo un <select> nativo funcional, no un campo invisible.
* Seam datepicker vacío a propósito: el ADR pide una interfaz Stimulus delgada para el día que un caso puntual necesite más que <input type="date"> (rango visual, calendario inline). Se crea el archivo, documentado, sin lógica — extraer una librería concreta sin este seam sería tener que tocar todas las vistas que usan date_field.
* Override de métodos con el mismo nombre de Rails (text_field, select...), no métodos nuevos tipo f.input: mantiene la API que cualquiera que conozca Rails ya sabe usar. Verifiqué en el código fuente de ActionView::Helpers::FormBuilder que select es un método real (no method_missing), así que super dentro de un bloque anidado en el método que lo llama funciona (es comportamiento estándar de Ruby, no un truco).
* tom_select no reutiliza el select de este mismo builder: si lo hiciera, el fieldset/label/hint se envolvería dos veces. Llama directo al select original de ActionView::Helpers::FormBuilder vía UnboundMethod#bind_call — mismo motivo que el punto anterior.

## Alternativas consideradas

* Select2 en vez de Tom Select → descartado en el ADR: Tom Select es su sucesor mantenido, sin dependencia de jQuery.
* Flatpickr para fechas → descartado en el ADR: sin releases desde 2020, clasificado "Inactive" por análisis de salud de dependencias. Inputs nativos cubren el 90% de los casos; el seam datepicker cubre el resto sin comprometerse hoy a una librería concreta.
* Gema de formularios completa (simple_form/formtastic) → no evaluada: el ADR ya fijó "form builder" como una pieza propia de este boilerplate, no una dependencia externa a mantener.
* Un método único form.input :attr que infiere el tipo de campo por columna → descartado por ahora: es más "magia" de la que pediste, y añade un caso más para depurar cuando algo no es un ActiveRecord. Si aparece una razón concreta, se agrega sin romper los métodos actuales (son independientes).

## Comandos

```bash
bundle add tom-select-rails --version "~> 2.5"
```

## Archivos

Gemfile — agrega junto a los demás gems de frontend:

```ruby
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Selects con búsqueda/tags/multi-selección [https://github.com/tysongach/tom-select-rails]
gem "tom-select-rails", "~> 2.5"
```

config/importmap.rb — agrega:

```ruby
pin "tom-select"
```

config/application.rb — agrega dentro de class Application:

```ruby
    # Don't generate system test files.
    config.generators.system_tests = nil

    # Todo form_with usa AdminFormBuilder sin tener que pasar `builder:` cada
    # vez (ver app/form_builders/admin_form_builder.rb). String, no la
    # constante directa: el autoloader todavía no está listo cuando este
    # archivo se evalúa.
    config.action_view.default_form_builder = "AdminFormBuilder"
```

app/form_builders/admin_form_builder.rb (nuevo — Zeitwerk autoload cualquier app/*, igual que ya pasa con app/policies/, no hace falta tocar autoload_paths):

```bash
touch 'app/form_builders/admin_form_builder.rb'
```

```ruby
# Form builder por defecto de toda la app (ver config/application.rb).
#
# Envuelve cada campo en el markup de DaisyUI v5 (fieldset + label + el input
# real + validator-hint) para que ningún módulo futuro (Setup 13 en adelante)
# tenga que repetir esa estructura a mano, como pasaba en sessions/passwords
# antes de esta fase.
#
# Usa las clases nativas de validación de DaisyUI v5 (`validator` +
# `validator-hint`, ver docs/conventions/forms.md) apoyadas en atributos
# HTML5 nativos (required, minlength, type="email"...) — sin JS. Los errores
# de servidor (object.errors) se muestran con ese mismo `validator-hint`.
class AdminFormBuilder < ActionView::Helpers::FormBuilder
  # Usado por `tom_select` para llamar al `select` original sin pasar por el
  # override de abajo (evitaría envolver el fieldset dos veces). Es un método
  # real en ActionView::Helpers::FormBuilder, no method_missing — bind_call
  # es seguro.
  NATIVE_SELECT = ActionView::Helpers::FormBuilder.instance_method(:select)
  private_constant :NATIVE_SELECT

  def text_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def email_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def password_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def number_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  # Input nativo de fecha — sin JS (ver ADR §3.4, Flatpickr descartado por
  # abandono). Si algún día hace falta time_field/datetime_local_field, el
  # patrón es idéntico: cópialo.
  def date_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def text_area(attribute, options = {})
    field(attribute, options, css_class: "textarea") { |opts| super(attribute, opts) }
  end

  def check_box(attribute, options = {}, checked_value = "1", unchecked_value = "0")
    label_text = options.delete(:label) { default_label(attribute) }
    hint_text  = options.delete(:hint)

    opts = options.dup
    opts[:class] = [ "checkbox", options[:class] ].compact.join(" ")

    @template.content_tag(:fieldset, class: "fieldset w-full") do
      @template.safe_join([
        @template.content_tag(:label, class: "label cursor-pointer justify-start gap-3") do
          @template.safe_join([ super(attribute, opts, checked_value, unchecked_value), label_text ])
        end,
        (hint(attribute, hint_text, error: false) if hint_text.present?)
      ].compact)
    end
  end

  # <select> nativo de Rails, estilizado. `label:`/`hint:` se aceptan en
  # options (3er argumento) o en html_options (4to) — el que te resulte
  # más natural en cada llamada.
  def select(attribute, choices, options = {}, html_options = {}, &block)
    passthrough = options.slice(:label, :hint)
    select_opts = options.except(:label, :hint)
    merged_html = html_options.reverse_merge(passthrough)

    field(attribute, merged_html, css_class: "select") do |opts|
      super(attribute, choices, select_opts, opts, &block)
    end
  end

  # <select> potenciado con Tom Select (búsqueda, tags, multi-selección).
  # `tom_select_options` viaja tal cual al constructor de TomSelect en JS
  # (ver app/javascript/controllers/tom_select_controller.js). Si el JS no
  # carga, esto sigue siendo un <select multiple> normal — no queda invisible.
  def tom_select(attribute, choices, options = {}, tom_select_options = {})
    select_opts = options.slice(:include_blank, :prompt, :selected, :disabled)

    field(attribute, options, css_class: "select") do |opts|
      opts[:data] = (opts[:data] || {}).merge(
        controller: "tom-select",
        "tom-select-options-value": tom_select_options.to_json
      )
      NATIVE_SELECT.bind_call(self, attribute, choices, select_opts, opts)
    end
  end

  private

  # Envuelve cualquier campo en fieldset + label + el input real + hint/error.
  # `css_class` es la clase base de DaisyUI para ese campo ("input" para casi
  # todos; "textarea"/"select" para los que la necesitan distinta).
  def field(attribute, options, css_class: "input")
    options    = options.dup
    label_text = options.delete(:label) { default_label(attribute) }
    hint_text  = options.delete(:hint)
    errors     = object.respond_to?(:errors) ? Array(object.errors[attribute]) : []
    message    = errors.first || hint_text

    opts = options.dup
    opts[:class] = [ css_class, "validator", options[:class] ].compact.join(" ")
    opts[:"aria-describedby"] = field_id(attribute, :hint) if message.present?

    @template.content_tag(:fieldset, class: "fieldset w-full") do
      @template.safe_join([
        label(attribute, label_text, class: "label"),
        yield(opts),
        hint(attribute, message, error: errors.any?)
      ].compact)
    end
  end

  def hint(attribute, message, error:)
    return if message.blank?

    css = error ? "validator-hint" : "label -mt-1 text-xs text-base-content/60"
    @template.content_tag(:p, message, id: field_id(attribute, :hint), class: css)
  end

  # object puede ser nil (form_with sin `model:`, como sessions/passwords) —
  # NilClass no tiene human_attribute_name, así que caemos a humanize.
  def default_label(attribute)
    klass = object.class
    klass.respond_to?(:human_attribute_name) ? klass.human_attribute_name(attribute) : attribute.to_s.humanize
  end
end
```

app/javascript/controllers/tom_select_controller.js (nuevo):

```bash
touch 'app/javascript/controllers/tom_select_controller.js'
```

```javascript
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Envuelve un <select> nativo con Tom Select. Uso normal: a través de
// `form.tom_select` (ver app/form_builders/admin_form_builder.rb), que ya
// agrega data-controller="tom-select" y el JSON de configuración por vos.
export default class extends Controller {
  static values = { options: Object }

  connect() {
    this.tomSelect = new TomSelect(this.element, this.optionsValue)
  }

  disconnect() {
    this.tomSelect?.destroy()
  }
}
```

app/javascript/controllers/datepicker_controller.js (nuevo — seam del ADR §3.4, vacío a propósito):

```bash
touch 'app/javascript/controllers/datepicker_controller.js'
```

```javascript
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
```

app/assets/tailwind/application.css — agrega al final:

```css
/*
 * ============================================================
 * TOM SELECT — integración visual con los tokens de DaisyUI (Setup 9)
 * ============================================================
 * No usamos el theme oficial de tom-select-rails: trae colores fijos que no
 * responden a --color-* ni a dark/light. Estos selectores corresponden a la
 * estructura DOM de Tom Select 2.6.x — si una versión futura cambia el
 * markup interno, ajusta aquí y confirma visualmente en /styleguide.
 */
.ts-wrapper.single .ts-control,
.ts-wrapper.multi .ts-control {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.25rem;
  min-height: 2.5rem;
  padding: 0.25rem 0.75rem;
  background-color: var(--color-base-100);
  border: var(--border, 1px) solid var(--color-base-300);
  border-radius: var(--radius-field);
  color: var(--color-base-content);
  cursor: text;
}

.ts-wrapper.focus .ts-control {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

.ts-wrapper.disabled .ts-control {
  opacity: 0.5;
  cursor: not-allowed;
}

.ts-control > input {
  background: transparent;
  border: 0;
  outline: none;
  color: inherit;
  flex: 1 1 auto;
  min-width: 4rem;
}

.ts-control .item {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.125rem 0.5rem;
  background-color: var(--color-base-200);
  border-radius: var(--radius-selector);
  font-size: 0.8125rem;
}

.ts-control .item .remove {
  cursor: pointer;
  opacity: 0.6;
  border-left: 0;
}

.ts-control .item .remove:hover {
  opacity: 1;
}

.ts-dropdown {
  background-color: var(--color-base-100);
  border: var(--border, 1px) solid var(--color-base-300);
  border-radius: var(--radius-field);
  box-shadow: 0 4px 12px rgb(0 0 0 / 0.1);
  margin-top: 0.25rem;
  overflow: hidden;
  z-index: 20;
}

.ts-dropdown .option {
  padding: 0.5rem 0.75rem;
  cursor: pointer;
  color: var(--color-base-content);
}

.ts-dropdown .option.active {
  background-color: var(--color-base-200);
}

.ts-dropdown .option.selected {
  background-color: var(--color-primary);
  color: var(--color-primary-content);
}

.ts-dropdown .no-results,
.ts-dropdown .create {
  padding: 0.5rem 0.75rem;
  color: var(--color-base-content);
  opacity: 0.6;
}
```

app/controllers/passwords_controller.rb — fix del bug de Pundit (una línea, junto al resto de opciones de clase):

```ruby
class PasswordsController < ApplicationController
  layout "application"

  skip_after_action :verify_pundit_authorization

  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  # ... el resto queda igual
```

app/views/sessions/new.html.erb (reemplaza):

```erb
<% content_for :title, "Iniciar sesión" %>

<div class="card w-full max-w-sm bg-base-100 shadow-xl">
  <div class="card-body">
    <h1 class="card-title justify-center text-2xl mb-4">Admin Gem</h1>

    <%= form_with url: session_path do |form| %>
      <%= form.email_field :email_address, label: "Correo", required: true, autofocus: true,
            autocomplete: "username" %>

      <%= form.password_field :password, label: "Contraseña", required: true, maxlength: 72,
            autocomplete: "current-password" %>

      <div class="text-right -mt-2 mb-4">
        <%= link_to "¿Olvidaste tu contraseña?", new_password_path, class: "link link-hover text-sm text-base-content/70" %>
      </div>

      <%= form.submit "Entrar", class: "btn btn-primary w-full" %>
    <% end %>
  </div>
</div>
```

app/views/passwords/new.html.erb (reemplaza):

```erb
<% content_for :title, "Recuperar contraseña" %>

<div class="card w-full max-w-sm bg-base-100 shadow-xl">
  <div class="card-body">
    <h1 class="card-title text-2xl mb-1">Recuperar contraseña</h1>
    <p class="text-sm text-base-content/70 mb-4">Te enviaremos instrucciones para restablecerla.</p>

    <%= form_with url: passwords_path do |form| %>
      <%= form.email_field :email_address, label: "Correo", required: true, autofocus: true,
            autocomplete: "username" %>

      <%= form.submit "Enviar instrucciones", class: "btn btn-primary w-full mt-2" %>
    <% end %>

    <div class="text-center mt-4">
      <%= link_to "Volver a iniciar sesión", new_session_path, class: "link link-hover text-sm" %>
    </div>
  </div>
</div>
```

app/views/passwords/edit.html.erb (reemplaza):

```erb
<% content_for :title, "Nueva contraseña" %>

<div class="card w-full max-w-sm bg-base-100 shadow-xl">
  <div class="card-body">
    <h1 class="card-title text-2xl mb-4">Elige una nueva contraseña</h1>

    <%= form_with url: password_path(params[:token]), method: :put do |form| %>
      <%= form.password_field :password, label: "Nueva contraseña", required: true, maxlength: 72,
            autocomplete: "new-password", hint: "Mínimo 12 caracteres." %>

      <%= form.password_field :password_confirmation, label: "Repite la contraseña", required: true,
            maxlength: 72, autocomplete: "new-password" %>

      <%= form.submit "Guardar", class: "btn btn-primary w-full mt-2" %>
    <% end %>
  </div>
</div>
```

app/models/styleguide_form.rb (nuevo — demo-only, no persiste, no tiene tabla):

```bash
touch 'app/models/styleguide_form.rb'
```

```ruby
# Modelo de demostración, exclusivo para /styleguide (Setup 9). No se persiste
# ni tiene tabla — existe solo para mostrar AdminFormBuilder con un objeto
# real, incluyendo un error simulado en :email para ver el validator-hint
# en rojo (ver #initialize).
class StyleguideForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :bio, :string
  attribute :birthdate, :date
  attribute :country, :string
  attribute :tags
  attribute :newsletter, :boolean, default: false

  def initialize(...)
    super
    errors.add(:email, "ya está en uso") # fuerza el estado de error en la demo
  end
end
```

app/controllers/pages_controller.rb (edita styleguide):

```ruby
  def styleguide
    @demo_form = StyleguideForm.new(name: "Ada Lovelace", country: "ar")
  end
```

app/views/pages/styleguide.html.erb — agrega después de la sección de Modal:

```erb
  <section class="card bg-base-100 shadow p-6 space-y-4">
    <h2 class="font-medium">Formularios (AdminFormBuilder)</h2>
    <p class="text-sm text-base-content/60 -mt-2">
      Cada campo trae su fieldset, label y validator-hint solo. El de "Email" fuerza
      un error de servidor para mostrar el estado inválido en rojo.
    </p>

    <%= form_with model: @demo_form, url: "#", method: :get do |form| %>
      <div class="grid sm:grid-cols-2 gap-x-4">
        <%= form.text_field :name, label: "Nombre" %>
        <%= form.email_field :email, label: "Email" %>
      </div>

      <%= form.text_area :bio, label: "Biografía", hint: "Máximo 280 caracteres.", rows: 3 %>

      <div class="grid sm:grid-cols-2 gap-x-4">
        <%= form.date_field :birthdate, label: "Fecha de nacimiento" %>
        <%= form.select :country, [ [ "Argentina", "ar" ], [ "México", "mx" ], [ "España", "es" ],
              [ "Chile", "cl" ], [ "Colombia", "co" ] ], label: "País", include_blank: "Selecciona un país" %>
      </div>

      <%= form.tom_select :tags, [ [ "Rails", "rails" ], [ "Hotwire", "hotwire" ], [ "Tailwind", "tailwind" ],
            [ "Pundit", "pundit" ], [ "Postgres", "postgres" ] ], label: "Tecnologías (Tom Select)", multiple: true %>

      <%= form.check_box :newsletter, label: "Quiero recibir noticias por correo" %>

      <%= render "components/button", text: "Enviar (demo, no hace nada)", type: "submit", variant: :primary %>
    <% end %>
  </section>
```

spec/form_builders/admin_form_builder_spec.rb (nuevo, pending — instanciar ActionView::Base a mano para testear un form builder aislado es frágil entre versiones de Rails; lo real y más confiable es la cobertura indirecta vía los request specs de abajo, así que esto queda anotado para Setup 15):

```bash
touch 'spec/form_builders/admin_form_builder_spec.rb'
```

```ruby
require "rails_helper"

RSpec.describe AdminFormBuilder do
  pending "add some examples to (or delete) #{__FILE__}"
end
```

spec/requests/sessions_spec.rb (nuevo):

```bash
touch 'spec/requests/sessions_spec.rb'
```

```ruby
require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /session/new" do
    it "renderiza el login con el markup de AdminFormBuilder" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<fieldset")
      expect(response.body).to include("input validator")
      expect(response.body).to include("Correo")
    end
  end
end
```

spec/requests/passwords_spec.rb (nuevo — valida el fix del bug de Pundit):

```bash
touch 'spec/requests/passwords_spec.rb'
```

```ruby
require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "renderiza sin el AuthorizationNotPerformedError que tenía antes de este fix" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end
end
```

docs/conventions/forms.md (nuevo):

```bash
touch 'docs/conventions/forms.md'
```

```markdown
# Convenciones de formularios — admin-gem

## Form builder por defecto
Todo `form_with` usa `AdminFormBuilder` automáticamente (`config.action_view.default_form_builder`
en `config/application.rb`) — no hace falta pasar `builder:`.

## Campos disponibles
`text_field`, `email_field`, `password_field`, `number_field`, `date_field`, `text_area`,
`select`, `tom_select`, `check_box`. Todos aceptan `label:` y `hint:` además de sus
opciones normales de Rails.

```erb
<%= form.text_field :name, label: "Nombre", hint: "Como aparece en tu perfil." %>
```

Sin `label:`, se usa `object.class.human_attribute_name(atributo)` humanizado. Los
errores del modelo se muestran solos en el mismo espacio que un `hint:` — nunca hace
falta chequear `object.errors.any?` a mano en la vista.

## select vs tom_select
`select` es el nativo de Rails, estilizado. `tom_select` es el mismo `<select>` con
búsqueda/tags/multi-selección vía Tom Select — úsalo con listas largas o selección
múltiple. Es progresivo: sin JS, sigue siendo un `<select>` normal.

## Inputs de fecha
`date_field` renderiza `<input type="date">` nativo — sin JS ni librería de calendario
(Flatpickr está abandonado, ver ADR §3.4). Para un caso puntual que necesite más
(rango visual, calendario inline), existe el seam `data-controller="datepicker"`
(hoy vacío a propósito) para enchufar una librería concreta sin tocar el resto.

## Validación
Los campos llevan la clase `validator` de DaisyUI v5: colorean el input según las
reglas HTML5 nativas (`required`, `pattern`, `minlength`, `type="email"`) sin JS.
`validator-hint` muestra el error del servidor cuando existe, o el `hint:` estático
si no hay error — nunca los dos a la vez.

## Cómo añadir un campo que el builder no tiene
Seguí el mismo patrón que los demás: `def radio_button(attribute, tag_value, options = {}); field(attribute, options) { |opts| super(attribute, tag_value, opts) }; end`.
```

docs/documentation/setup_99_TODO.md — mueve Setup 8 a hecho, Setup 9 a CURRENT:

```markdown
* Setup 7  — Authorization                   (Pundit + Role/Permission)
* Setup 8  — Components                      (partials/helpers/Stimulus del design system)

## CURRENT:

* Setup 9  — Forms                           (form builder, Tom Select, inputs nativos de fecha)

## TODO:
## Setup 10 — Tables / Filtros / Pagy         (tabla reutilizable, filtros por allowlist)
```

## Verificación de consistencia

bundle add deja tom-select-rails en Gemfile.lock. docs/documentation/setup_99_TODO.md marca Setup 8 como hecho y Setup 9 como CURRENT. Sessions y Passwords siguen siendo los únicos formularios reales de la app — ambos migrados, ninguno queda con form-control/input-bordered (sintaxis v4).

## Validaciones

```bash
bin/importmap json
# → confirma que "tom-select" aparece pineado (y revisa si vendorea el build
#   "complete" con plugins — si más adelante querés remove_button en los tags
#   de un multi-select, agrégalo vía tom_select_options: { plugins: ["remove_button"] }
#   una vez confirmado que el build lo trae)

bin/dev
# → /session/new y /passwords/new: ya no revientan, se ven con fieldset/label/
#   validator (antes: form-control/input-bordered, sintaxis v4)
# → /passwords/new específicamente: antes de este fix daba 500
#   (Pundit::AuthorizationNotPerformedError) — confirmá que ahora carga
# → /styleguide: sección "Formularios" — el campo Email se ve en rojo con
#   "ya está en uso", el select de País funciona nativo, el de Tecnologías
#   abre el dropdown de Tom Select con búsqueda y permite elegir varias
# → probá el modo oscuro en esa sección: Tom Select debe verse consistente
#   (usa las mismas variables --color-* que el resto)

bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

validator/validator-hint son puramente visuales (CSS sobre pseudo-clases :valid/:invalid nativas) — nunca reemplazan la validación real del modelo ni del controlador; alguien con JS deshabilitado o que edite el DOM sigue estando sujeto a las validaciones de ActiveModel del lado del servidor.
El fix de PasswordsController es puramente de disponibilidad (evita un 500), no cambia qué está o no autorizado — esa página ya estaba fuera del alcance de Pundit intencionalmente vía allow_unauthenticated_access, solo le faltaba el análogo para verificación de autorización.

## Mantenibilidad y compatibilidad futura

Setup 13 (Usuarios) no reinventa capas de formulario: cada campo es una línea (form.text_field :email_address, label: "Correo") en vez de fieldset+label+hint a mano como en Setup 6.
Si ese módulo necesita un select de roles, es form.tom_select :role_id, Role.pluck(:name, :id) y ya.
El seam datepicker evita que decidir una librería de calendario hoy (con Flatpickr abandonado y sin un reemplazo claro todavía) bloquee esta fase.