# Setup 10 — Tables / Filtros / Pagy

## Objetivo

Tabla reutilizable (`components/table`), paginación con Pagy 43 (`~> 43.0`, fijado en tu ADR), y filtros por lista blanca de scopes — nunca Ransack, tal como dejaste decidido en §8 del ADR. Dogfoodea todo esto en un recurso real por primera vez: `RolesController#index` (Setup 7 ya tiene datos reales — 5 roles sembrados — y hasta ahora nada los lista).

## De paso: `PermissionResource` nunca se incluyó

Antes de escribir `RolePolicy` fui a ver cómo `ApplicationPolicy` resuelve `permitted?` para entender el mecanismo exacto, y encontré que `app/policies/application_policy.rb` llama a `permitted?(:view)` en `index?`/`show?`/etc., pero `include PermissionResource` está comentado en las dos clases (`ApplicationPolicy` y su `Scope`) — y `app/policies/concerns/permission_resource.rb` **no existe en el repo**. El `WidgetPolicy` de tu spec de Setup 7 no lo nota porque sobreescribe todos los métodos a mano, sin pasar por `permitted?`. Cualquier policy real que dependa de los defaults heredados (como `RolePolicy` de abajo) reventaría con `NameError: undefined method 'permitted?'`. Lo incluyo en "Archivos" — es la pieza que hace cierta la promesa de Setup 7 ("nada que registrar, el nombre de la policy define el recurso").

## Decisiones arquitectónicas

* **Pagy 43 (`~> 43.0`)**: es una "leap version" — API completamente rediseñada, verifiqué la guía de migración oficial porque mi conocimiento de Pagy pre-43 (`pagy(scope)`, `pagy_nav`) ya no aplica. Ahora: `include Pagy::Method` (no `Pagy::Backend`/`Pagy::Frontend`, que se eliminaron), `pagy(:offset, scope)` retorna `[pagy, records]`, y la navegación se renderiza con métodos de instancia (`@pagy.series_nav`, `@pagy.info_tag`) en vez de helpers sueltos.
* **`series_nav` con clases de DaisyUI inyectadas, no CSS custom**: Pagy expone `link_extra:`/`active_link_extra:`/`nav_extra:` para inyectar atributos HTML directo en cada tag que genera — se lo confirmé al mantenedor de Pagy en una discusión pública donde recomienda exactamente este mecanismo para integrar con Tailwind. Le paso las clases `join`/`btn` de DaisyUI ahí mismo: cero CSS nuevo, a diferencia de Tom Select en Setup 9 (que si necesitó CSS propio porque no tiene ese hook).
* **Filtros: scopes explícitos + lista blanca en el controlador, nunca Ransack**: es literal del ADR §8 ("Ransack... advisories de seguridad relacionados con exposición de atributos/asociaciones no previstas vía parámetros"). `Filterable#filterable_by` declara qué *scopes* (no qué columnas crudas) puede invocar cada controlador; cualquier otra clave en `params[:q]` se descarta antes de tocar la base de datos.
* **Los scopes de filtro viven en el modelo, no en el controlador**: `Role.by_name`/`Role.by_key` son ILIKE parciales (una tabla admin sin búsqueda parcial es inútil en la práctica) con `sanitize_sql_like` para que el valor del usuario no pueda alterar el patrón. Mantiene la regla de "lógica de negocio nunca en el controlador" de tu propia tabla de componentes (Setup 8, ADR §9).
* **Tabla como partial con locals (columnas como datos, no bloques)**: mismo patrón #1 de Setup 8. Cada columna es `{ label:, attribute: }` o `{ label:, format: ->(record) {...} }` para lo calculado — cubre el caso de Roles (columna "Permisos" es `role.permissions.count`, no un atributo directo) sin necesitar `yield` por columna.
* **`Roles#index` de solo lectura por ahora**: crear/editar/borrar roles necesita formularios (Setup 9, ya tenés) pero también decisiones de UX que no son "Tables" (¿puede un admin quitarse su propio rol? ¿bloquear borrar el último rol super?) — esas se resuelven mejor cuando el módulo de referencia completo (Usuarios, Setup 13) fije el patrón CRUD entero, no a mitad de esta fase.

## Alternativas consideradas

* **Ransack** → descartado en el ADR, motivo de seguridad ya citado arriba.
* **`kaminari`/`will_paginate`** → Pagy ya fijado en el ADR: más liviano, sin dependencias, activamente mantenido.
* **Componente de tabla con `yield` por celda (`render layout: "components/table"`)** → descartado: para el 90% de columnas (texto plano de un atributo) sería más verboso que `{ label:, attribute: }`; `format:` cubre el resto sin forzar bloques en cada columna.
* **CRUD completo de Roles en esta fase** → descartado, ver decisión de arriba.

## Comandos

```bash
bundle add pagy --version "~> 43.0"
```

```ruby
# Agnostic pagination in plain ruby.
gem "pagy", "~> 43.0"
```

## Archivos

**app/policies/concerns/permission_resource.rb** (nuevo — la pieza que faltaba de Setup 7):

```bash
mkdir app/policies/concerns
touch app/policies/concerns/permission_resource.rb
```

```ruby
# Deriva el nombre del recurso ("roles", "users"...) a partir del nombre de
# la clase de policy que lo incluye, y construye la clave de permiso
# correspondiente ("roles.view", "roles.manage").
module PermissionResource
  private

  def resource_name
    self.class.name.sub(/Policy(::Scope)?\z/, "").underscore.pluralize
  end

  def permission_key(level)
    "#{resource_name}.#{level}"
  end

  def permitted?(level)
    user&.permits?(permission_key(level))
  end
end
```

**app/policies/application_policy.rb** — descomenta el `include` en las dos clases:

```ruby
class ApplicationPolicy
  include PermissionResource

  attr_reader :user, :record
  # ... el resto queda igual

  class Scope
    include PermissionResource

    attr_reader :user, :scope
    # ... el resto queda igual
```

**Gemfile** — agrega:

```ruby
# Paginación [https://ddnexus.github.io/pagy] — fijado en el ADR: rediseño
# total en la v43 ("leap version"), API distinta a cualquier tutorial pre-43.
gem "pagy", "~> 43.0"
```

**config/initializers/pagy.rb** (nuevo):

```bash
touch config/initializers/pagy.rb
```

```ruby
# Pagy 43 redujo los requisitos de configuración ~99% según su propio
# changelog — no hace falta requerir "extras" como en versiones viejas.
# Solo fijamos lo único que sí queremos decidir nosotros: filas por página.
Pagy::OPTIONS[:limit] = 20
```

**app/controllers/application_controller.rb** — agrega junto a los demás `include`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Method
  include Filterable
```

**app/controllers/concerns/filterable.rb** (nuevo):

```bash
touch app/controllers/concerns/filterable.rb
```

```ruby
# Filtrado de tablas administrativas por lista blanca (ver ADR §8: nada de
# "filtrado mágico" tipo Ransack). `filterable_by` declara qué *scopes* puede
# invocar el controlador — nunca columnas crudas — así que cualquier otra
# clave en params[:q] se descarta acá, antes de tocar la base de datos.
module Filterable
  extend ActiveSupport::Concern

  included do
    class_attribute :filterable_scopes, default: []
  end

  class_methods do
    # Cada símbolo debe ser también el nombre de un scope en el modelo que
    # este controlador filtra (filterable_by :by_name requiere que el modelo
    # defina scope :by_name).
    def filterable_by(*scopes)
      self.filterable_scopes = scopes.map(&:to_sym)
    end
  end

  private

  def apply_filters(scope)
    filter_params.each { |name, value| scope = scope.public_send(name, value) if value.present? }
    scope
  end

  def filter_params
    params.fetch(:q, ActionController::Parameters.new).to_unsafe_h.symbolize_keys.slice(*filterable_scopes)
  end
end
```

**app/models/role.rb** — agrega los scopes:

```ruby
class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  # Parcial (ILIKE), no exacta — es la que de verdad sirve en un filtro de
  # tabla administrativa. sanitize_sql_like escapa % y _ del valor del
  # usuario para que no altere el patrón (ver Filterable).
  scope :by_name, ->(value) { where("name ILIKE ?", "%#{sanitize_sql_like(value)}%") }
  scope :by_key,  ->(value) { where("key ILIKE ?", "%#{sanitize_sql_like(value)}%") }

  def permits?(key)
    permission_keys.include?(key.to_s)
  end

  private

  def permission_keys
    @permission_keys ||= permissions.pluck(:key)
  end
end
```

**app/policies/role_policy.rb** (nuevo — vacío a propósito, ver Setup 7):

```bash
touch app/policies/role_policy.rb
```

```ruby
class RolePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end
end
```

**app/controllers/roles_controller.rb** (nuevo):

```bash
bin/rails generate controller Roles index
```

```ruby
class RolesController < ApplicationController
  filterable_by :by_name, :by_key

  def index
    scope = apply_filters(policy_scope(Role)).order(:name)
    @pagy, @roles = pagy(:offset, scope)
  end
end
```

**config/routes.rb** — agrega:

```ruby
  resource :session
  resources :passwords, param: :token
  resources :roles, only: :index
```

**db/seeds.rb** — agrega los dos permisos nuevos a la lista (una línea):

```ruby
permission_keys = %w[users.view users.manage roles.view roles.manage]
```

**app/helpers/icons_helper.rb** — agrega al hash `ICONS` (icono "key"; confirmá cómo se ve en `/styleguide` — es el único de esta fase que no verifiqué contra un uso previo en tu propio código):

```ruby
    key: '<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 5.25a3 3 0 0 1 3 3m3 0a6 6 0 0 1-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1 1 21.75 8.25Z" />',
```

**app/views/layouts/_sidebar.html.erb** — habilita el ítem de Roles:

```erb
  nav_items = [
    { label: "Inicio", icon: :home, path: root_path, available: true },
    { label: "Roles", icon: :key, path: roles_path, available: true },
    { label: "Usuarios", icon: :users, path: nil, available: false },
    { label: "Catálogos", icon: :squares_2x2, path: nil, available: false },
    { label: "Configuración", icon: :cog_6_tooth, path: nil, available: false }
  ]
```

**app/views/components/_table.html.erb** (nuevo):

```bash
touch app/views/components/_table.html.erb
```

```erb
<%#
  Tabla reutilizable.
  columns: [{ label: "Nombre", attribute: :name }, { label: "X", format: ->(r) { ... } }]
  records: cualquier Enumerable (normalmente una página ya paginada).
  Si records está vacío, renderiza components/empty_state en vez de una tabla vacía.
%>
<%
  columns            = local_assigns.fetch(:columns)
  records            = local_assigns.fetch(:records)
  empty_title        = local_assigns.fetch(:empty_title, "Sin resultados")
  empty_description  = local_assigns[:empty_description]
%>
<% if records.none? %>
  <%= render "components/empty_state", title: empty_title, description: empty_description %>
<% else %>
  <div class="overflow-x-auto">
    <table class="table">
      <thead>
        <tr>
          <% columns.each do |column| %>
            <th><%= column[:label] %></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <% records.each do |record| %>
          <tr>
            <% columns.each do |column| %>
              <td>
                <%= column[:format] ? column[:format].call(record) : record.public_send(column[:attribute]) %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
<% end %>
```

**app/views/roles/index.html.erb** (nuevo):

```erb
<% content_for :title, "Roles" %>

<h1 class="text-2xl font-semibold mb-4">Roles</h1>

<%= render(layout: "components/card") do %>
  <%= form_with url: roles_path, method: :get do |form| %>
    <div class="flex flex-wrap items-end gap-3 mb-4">
      <div class="w-48">
        <%= form.text_field :name, label: "Nombre", value: params.dig(:q, :name),
              placeholder: "Buscar...", name: "q[name]" %>
      </div>
      <div class="w-48">
        <%= form.text_field :key, label: "Clave", value: params.dig(:q, :key),
              placeholder: "Buscar...", name: "q[key]" %>
      </div>
      <%= render "components/button", text: "Filtrar", type: "submit", variant: :outline %>
      <% if params[:q].present? %>
        <%= render "components/button", text: "Limpiar", href: roles_path, variant: :ghost %>
      <% end %>
    </div>
  <% end %>

  <%= render "components/table",
        records: @roles,
        empty_title: "Sin roles que coincidan",
        empty_description: "Ajusta o limpia los filtros.",
        columns: [
          { label: "Nombre", attribute: :name },
          { label: "Clave", attribute: :key },
          { label: "Permisos", format: ->(role) { role.permissions.count } },
          { label: "Usuarios", format: ->(role) { role.users.count } }
        ] %>

  <div class="flex items-center justify-between mt-4">
    <p class="text-sm text-base-content/60"><%== @pagy.info_tag %></p>
    <%== @pagy.series_nav(
      nav_extra: 'class="join"',
      link_extra: 'class="join-item btn btn-sm"',
      active_link_extra: 'class="join-item btn btn-sm btn-active"'
    ) %>
  </div>
<% end %>
```

**spec/policies/role_policy_spec.rb** (nuevo — regresión directa del bug de `PermissionResource`):

```bash
bin/rails generate pundit:policy Role
```

```ruby
require "rails_helper"

RSpec.describe RolePolicy, type: :policy do
  describe RolePolicy do
    subject { described_class }

    let(:role) { create(:role, name: "Editor", key: "editor") }
    let(:user) { create(:user, role: role) }
    let(:record) { Role }

    context "con permiso roles.view" do
      before { role.permissions << create(:permission, key: "roles.view") }

      permissions :index?, :show? do
        it { is_expected.to permit(user, record) }
      end

      permissions :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    context "sin ningún permiso" do
      permissions :index?, :create? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    describe "Scope" do
      it "resuelve el scope completo con permiso de vista" do
        role.permissions << create(:permission, key: "roles.view")
        expect(described_class::Scope.new(user, Role.all).resolve).to include(role)
      end

      it "resuelve un scope vacío sin permiso" do
        sin_permiso = create(:user, role: create(:role, name: "Sin permisos", key: "sin_permisos"))
        expect(described_class::Scope.new(sin_permiso, Role.all).resolve).to be_empty
      end
    end
  end
end
```

**spec/requests/roles_spec.rb** (nuevo):

```ruby
require "rails_helper"

RSpec.describe "Roles", type: :request do
  describe "GET /roles" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get roles_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
```

**docs/conventions/tables.md** (nuevo):

```bash
touch docs/conventions/tables.md
```

```markdown
# Convenciones de tablas y filtros — admin-gem

## Componente de tabla
`render "components/table", columns: [...], records: @algo, empty_title: "..."`.
Cada columna es `{ label:, attribute: }` (llama `record.public_send(attribute)`) o
`{ label:, format: ->(record) { ... } }` para contenido calculado. Si `records` está
vacío, renderiza `components/empty_state` en vez de una tabla vacía.

## Paginación (Pagy 43)
`include Pagy::Method` ya está en `ApplicationController`.

```ruby
@pagy, @roles = pagy(:offset, apply_filters(policy_scope(Role)).order(:name))
```

```erb
<%== @pagy.info_tag %>
<%== @pagy.series_nav(
  nav_extra: 'class="join"', link_extra: 'class="join-item btn btn-sm"',
  active_link_extra: 'class="join-item btn btn-sm btn-active"'
) %>
```

`<%==` (doble `=`), no `<%=` — Pagy no marca sus strings como `html_safe` a propósito
(es agnóstico de Rails). Las clases `join`/`btn` son de DaisyUI, inyectadas vía las
opciones `*_extra` de Pagy — no hace falta CSS custom para la paginación.

## Filtros: lista blanca de scopes, nunca Ransack
Decisión del ADR (advisories de seguridad de Ransack por exposición de atributos no
previstos). El flujo:

1. El modelo define scopes explícitos y seguros: `scope :by_name, ->(v) { where("name ILIKE ?", "%#{sanitize_sql_like(v)}%") }`.
2. El controlador declara la lista blanca: `filterable_by :by_name, :by_key`.
3. `apply_filters(scope)` solo invoca los scopes declarados — cualquier otra clave en
   `params[:q]` se descarta antes de tocar la base de datos.

Nunca agregues a `filterable_by` un scope que no valide/escape su propio input.

## Cómo se ve en un controlador nuevo (ej. Setup 13, Usuarios)
```ruby
class UsersController < ApplicationController
  filterable_by :by_email

  def index
    @pagy, @users = pagy(:offset, apply_filters(policy_scope(User)).order(:email_address))
  end
end
```
```

**docs/documentation/setup_99_TODO.md** — mueve Setup 9 a hecho, Setup 10 a CURRENT:

```markdown
* Setup 9  — Forms                           (form builder, Tom Select, inputs nativos de fecha)

## CURRENT:

* Setup 10 — Tables / Filtros / Pagy         (tabla reutilizable, filtros por allowlist)

## TODO:

* Setup 11 — Charts                          (wrapper ApexCharts v6.x)
```

## Verificación de consistencia

`bundle add` deja Pagy en Gemfile.lock. Roles es la primera lista real de la app — Usuarios (Setup 13) reutiliza `components/table`, `Filterable` y el patrón `pagy(:offset, ...)` tal cual, sin inventar nada nuevo. El fix de `PermissionResource` hace que **cualquier** policy nueva (no solo `RolePolicy`) funcione con cuerpo vacío de ahora en más.

## Validaciones

```bash
bin/rails db:seed
# → agrega roles.view/roles.manage a super y admin (idempotente, podés correrlo
#   las veces que quieras)

bin/rails console
# > RolePolicy.new(User.first, Role).index? => true (si tu admin sembrado tiene
#   rol "super" o "admin")
# > Pagy::OPTIONS[:limit] => 20

bin/dev
# → clic en "Roles" en el sidebar: lista los 5 roles sembrados, paginación visible
#   solo si hay más de 20 (con 5 no debería aparecer — probá bajando el límite a
#   2 en el initializer temporalmente para ver la navegación en acción)
# → filtrá por "Nombre" o "Clave": el resultado se reduce, "Limpiar" reaparece
#   y borra el filtro
# → probá con un usuario sin permiso roles.view (creá uno con el rol "guest" del
#   seed): debería rebotar con el flash "No tienes permiso" hacia atrás

bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

`Filterable` nunca interpola una columna arbitraria en SQL: los nombres que llegan a `public_send` son los símbolos que el propio controlador declaró en código (`filterable_by`), nunca algo que venga de `params`. Los valores del usuario solo llegan como argumento de un scope que decide cómo tratarlos (`sanitize_sql_like` en los dos que existen hoy). El fix de `PermissionResource` es la corrección de un fail-open latente: antes de este fix, cualquier policy nueva que dependiera de los defaults heredados habría reventado con `NameError` en vez de autorizar o denegar — no exponía nada, pero tampoco protegía nada, porque simplemente nunca llegó a usarse.

## Mantenibilidad y compatibilidad futura

Setup 13 (Usuarios) copia el patrón entero de esta fase: `filterable_by`, `pagy(:offset, ...)`, `components/table` — cero piezas nuevas, solo `UserPolicy` (vacía, como `RolePolicy`) y los permisos `users.view`/`users.manage` que ya existen desde Setup 7. Si un módulo futuro necesita un filtro que Rails-way no cubre bien con `ILIKE` (rango de fechas, `IN` con múltiples valores), el mismo mecanismo de `filterable_by` + scope explícito lo soporta sin tocar `Filterable`.

# ERROR DETECTADO - RESPUESTA DEL PROBLEMA

Buen ojo — hay un bug real en `Filterable`, no es nada que quede "para después".

## El bug

`filterable_by :by_name, :by_key` guarda esos símbolos tal cual, y `filter_params` hace `params[:q].slice(*filterable_scopes)` — o sea, busca literalmente las claves `"by_name"`/`"by_key"` dentro de `params[:q]`. Pero el formulario manda `q[name]` y `q[key]` (los nombres de columna, no los nombres de los scopes). `slice` nunca encuentra coincidencias → `filter_params` siempre da `{}` → `apply_filters` nunca llama a ningún scope. Por eso ves la lista completa pero el filtro no hace nada: params[:q] sí le llega al controlador, pero `Filterable` está buscando las claves equivocadas adentro.

## El fix

Hay que mapear la clave pública (`name`, `key`) al scope real (`by_name`, `by_key`), no asumir que son la misma palabra:

**app/controllers/concerns/filterable.rb** (reemplaza el contenido):

```ruby
# Filtrado de tablas administrativas por lista blanca (ADR: nada de "filtrado
# mágico" tipo Ransack). `filterable_by` mapea la clave pública de params[:q]
# al scope que la resuelve — nunca al revés. Cualquier clave que no esté en
# ese mapa se descarta acá, antes de tocar la base de datos.
module Filterable
  extend ActiveSupport::Concern

  included do
    class_attribute :filterable_scopes, default: {}
  end

  class_methods do
    # filterable_by(name: :by_name, key: :by_key) acepta ?q[name]=... y
    # llama Role.by_name(...) — la clave pública no tiene que llamarse igual
    # que el scope.
    def filterable_by(mapping)
      self.filterable_scopes = mapping.symbolize_keys
    end
  end

  private

  def apply_filters(scope)
    filter_params.each do |key, value|
      scope_method = filterable_scopes[key]
      scope = scope.public_send(scope_method, value) if scope_method && value.present?
    end
    scope
  end

  def filter_params
    params.fetch(:q, ActionController::Parameters.new).to_unsafe_h.symbolize_keys.slice(*filterable_scopes.keys)
  end
end
```

**app/controllers/roles_controller.rb** (cambia solo la primera línea):

```ruby
class RolesController < ApplicationController
  filterable_by name: :by_name, key: :by_key

  def index
    scope = apply_filters(policy_scope(Role)).order(:name)
    @pagy, @roles = pagy(:offset, scope)
  end
end
```

La vista (`roles/index.html.erb`) queda igual — ya mandaba `q[name]`/`q[key]`, que ahora sí coincide con las claves del mapa.

## Sobre strong params

Tu instinto de que faltaba algo tipo strong params está bien, pero no es lo mismo que falte acá. Strong params existe para el caso "voy a hacer mass-assignment sobre un modelo" (`User.new(params)`) — evita que alguien cuele un atributo que no debería poder setear (`is_admin: true`). Acá no hay mass-assignment: cada valor de `params[:q]` se pasa como argumento a UN scope específico que el controlador ya declaró en código, nunca a un modelo entero. `filterable_scopes` (la lista blanca de `filterable_by`) cumple exactamente ese mismo rol de seguridad — decide qué puede ejecutarse — solo que a nivel de "qué scope" en vez de "qué atributo". No hace falta `permit` acá, y no es algo que quede pendiente para un setup futuro; para lectura/filtrado ya está completo. Donde sí vas a necesitar `permit` de verdad es en Setup 13, cuando `UsersController#create/#update` reciban un formulario completo para guardar en el modelo — ahí sí es mass-assignment real.

Sobre lo de "descomentar el resolve" en `role_policy.rb`: si tenés algo ahí que no sea exactamente

```ruby
class RolePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end
end
```

(es decir, si `Scope` tiene un `resolve` propio, comentado o no) — volvé a esta versión vacía. `resolve` ya existe heredado de `ApplicationPolicy::Scope` (`permitted?(:view) ? scope.all : scope.none`); si en algún momento la lista te apareció vacía y "arreglaste" poniendo `resolve { scope.all }` a mano, eso no arregla nada — solo apaga el chequeo de permiso (cualquiera vería la lista, tenga o no `roles.view`). Si la lista te aparecía vacía con la versión heredada, el motivo más probable es que tu usuario logueado no tiene el permiso `roles.view` todavía — corré `bin/rails db:seed` de nuevo (es idempotente) y confirmá en consola: `User.first.permits?("roles.view")`.