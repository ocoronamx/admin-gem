# Setup 12 — Dashboard

## Objetivo

Landing page real (reemplaza `root` de `pages#styleguide` a `dashboard#index`) con métricas reales donde existen (Roles, Permisos, Usuarios, Sesiones — todas cuentan filas reales) y un chart de actividad con datos de ejemplo, marcados como tales en la propia UI — tal como pide tu ADR ("demo data, claramente marcada").

## Decisiones arquitectónicas

* **Los 4 contadores son datos reales, no demo**: `Role.count`, `Permission.count`, `User.count`, `Session.count` existen de verdad desde Setup 7. Solo el chart de "Actividad" es inventado — no hay todavía ningún evento real que trackear (eso llega con `AuditLog` en Setup 14) — así que ahí sí necesitaba una marca explícita.
* **La marca de "datos de ejemplo" vive en la UI, no solo en un comentario de código**: un `badge_helper` (`components/badge` ya lo tenés) + una frase visible. Un comentario en el controlador no evita que alguien clone el boilerplate, mire el dashboard y crea que esos números son reales.
* **`skip_after_action :verify_pundit_authorization`, mismo patrón que `PagesController`**: el dashboard es una landing compartida, no un recurso administrable — no tiene sentido pedirle un permiso `dashboard.view` a algo que cualquier usuario autenticado debería poder ver.
* **La tarjeta de "Roles" sí respeta permisos, aunque el controlador entero esté fuera de Pundit**: uso `policy(Role).index?` en la vista para decidir si el número es un link a `/roles` o un texto plano. Es la forma correcta de usar Pundit fuera de un `index`/`show` — consultar la policy directamente, sin necesitar `authorize`/`policy_scope`. Evita un link muerto para quien no tiene `roles.view`.
* **Nada de un modelo/servicio para los datos falsos**: un array armado inline en el controlador, comentado explícitamente como demo. Esconderlo detrás de un objeto le resta la transparencia que buscás ("claramente marcada") — cualquiera que abra el controlador ve de inmediato que es inventado.

## Alternativas consideradas

* **Gatear el dashboard entero con Pundit (`DashboardPolicy`)** → descartado: agregaría una policy vacía + un permiso `dashboard.view` que habría que sembrar y asignar a todos los roles igual, sin ganar nada — es más simple tratarlo como página de sistema, igual que `/styleguide`.
* **Contadores también gateados con `policy(...).index?` cada uno** → descartado para Permisos/Usuarios/Sesiones: son agregados (un número), no la lista — mucho menor sensibilidad que exponer los registros, y todavía no existe ni `PermissionPolicy` ni `UsersController`. Se revisita si en el futuro alguno de esos números se considera sensible por sí solo.
* **Chart con datos reales pero poco interesantes** (ej. `Role.group_by_day(:created_at).count`, que con 5 filas sembradas el mismo día da una línea plana) → descartado: sería técnicamente "real" pero visualmente inútil como demo del wrapper, y further, seguiría sin ser un dato de negocio real — la falsa sensación de realismo es peor que la demo declarada.

## Comandos

Ninguno (solo rutas/controlador/vista).

## Archivos

**config/routes.rb** — reemplaza la línea de `root`:

```ruby
  resources :roles, only: :index
  root to: "dashboard#index"
```

**app/controllers/dashboard_controller.rb** (nuevo):

```bash
bin/rails generate controller Dashboard index
```

```ruby
class DashboardController < ApplicationController
  # Landing compartida, no un recurso administrable — mismo criterio que
  # PagesController para /styleguide.
  skip_after_action :verify_pundit_authorization

  def index
    @stats = {
      users: User.count,
      roles: Role.count,
      permissions: Permission.count,
      sessions: Session.count
    }

    # Datos de ejemplo — no existe todavía una fuente real de "actividad"
    # (eso llega con AuditLog en la Fase 14). Reemplazá esto por una consulta
    # real en cuanto haya un evento que valga la pena graficar. Marcado
    # también en la vista (badge "Datos de ejemplo") — no alcanza con el
    # comentario acá.
    @demo_activity = (6.days.ago.to_date..Date.current).map { |date| { date: date, value: rand(20..80) } }
  end
end
```

**app/views/dashboard/index.html.erb** (nuevo):

```erb
<% content_for :title, "Dashboard" %>

<h1 class="text-2xl font-semibold mb-4">Dashboard</h1>

<div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
  <div class="card bg-base-100 shadow p-5">
    <p class="text-sm text-base-content/60">Usuarios</p>
    <p class="text-3xl font-semibold"><%= @stats[:users] %></p>
  </div>

  <div class="card bg-base-100 shadow p-5">
    <p class="text-sm text-base-content/60">Roles</p>
    <p class="text-3xl font-semibold">
      <% if policy(Role).index? %>
        <%= link_to @stats[:roles], roles_path, class: "link link-hover" %>
      <% else %>
        <%= @stats[:roles] %>
      <% end %>
    </p>
  </div>

  <div class="card bg-base-100 shadow p-5">
    <p class="text-sm text-base-content/60">Permisos</p>
    <p class="text-3xl font-semibold"><%= @stats[:permissions] %></p>
  </div>

  <div class="card bg-base-100 shadow p-5">
    <p class="text-sm text-base-content/60">Sesiones activas</p>
    <p class="text-3xl font-semibold"><%= @stats[:sessions] %></p>
  </div>
</div>

<div class="card bg-base-100 shadow p-6">
  <div class="flex items-center gap-2 mb-1">
    <h2 class="font-medium">Actividad</h2>
    <span class="badge badge-warning badge-sm">Datos de ejemplo</span>
  </div>
  <p class="text-sm text-base-content/60 mb-3">
    Todavía no hay una fuente real de actividad — esto solo muestra cómo se ve
    un chart acá. Reemplazalo cuando exista un evento real que trackear.
  </p>

  <%= chart_tag type: :area, height: 260,
        series: [ { name: "Actividad (demo)", data: @demo_activity.map { |d| d[:value] } } ],
        xaxis: { categories: @demo_activity.map { |d| d[:date].strftime("%d %b") } } %>
</div>
```

**spec/requests/dashboard_spec.rb** (nuevo):

```ruby
require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
```

## FIX

Para un recurso admin como Roles, la denegación explícita es el comportamiento correcto — coherente con cómo ya se comportan `show?`/`create?`/etc. Se arregla agregando `authorize` además de `policy_scope`:

**app/controllers/roles_controller.rb**:
```ruby
class RolesController < ApplicationController
  filterable_by name: :by_name, key: :by_key

  def index
    authorize Role
    scope = apply_filters(policy_scope(Role)).order(:name)
    @pagy, @roles = pagy(:offset, scope)
  end
end
```

**docs/conventions/tables.md** — actualiza el ejemplo para que Usuarios (y cualquier módulo futuro) nazca con el patrón correcto:

```ruby
class UsersController < ApplicationController
  filterable_by email: :by_email

  def index
    authorize User
    @pagy, @users = pagy(:offset, apply_filters(policy_scope(User)).order(:email_address))
  end
end
```

**spec/requests/roles_spec.rb** — agrega el caso que faltaba:

```ruby
require "rails_helper"

RSpec.describe "Roles", type: :request do
  describe "GET /index" do
    context "cuando el usuario está autenticado" do
      let(:role) do
        Role.create!(name: "Super Administrador", key: "super_admin").tap do |role|
          role.permissions << Permission.create!(key: "roles.view")
        end
      end

      let(:user) do
        User.create!(
          email_address: "admin@example.com",
          password: "password123456",
          role: role
        )
      end

      before do
        post session_path, params: {
          email_address: user.email_address,
          password: user.password
        }
      end

      it "returns http success" do
        get roles_path
        expect(response).to have_http_status(:success)
      end
    end

    context "cuando no hay usuario autenticado" do
      it "redirige a iniciar sesión" do
        get roles_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    it "rechaza a un usuario autenticado sin permiso roles.view" do
      user = create(:user, email_address: "foo@example.com", password: "password123456",
                    role: create(:role, name: "Sin permisos", key: "sin_permisos"))
      post session_path, params: { email_address: user.email_address, password: user.password }

      get roles_path

      expect(response).to redirect_to(root_path)
    end
  end
end
```

**docs/documentation/setup_99_TODO.md** — mueve Setup 12 a hecho, Setup 13 a CURRENT:

```markdown
* Setup 11 — Charts                          (wrapper ApexCharts v6.x)
* Setup 12 — Dashboard                       (demo data, claramente marcada)

## CURRENT:
* Setup 13 — Usuarios                        (módulo de referencia)

## TODO:
* Setup 14 — Auditoría                       (Auditable concern + AuditLog propio)
```

## Verificación de consistencia

`/styleguide` sigue existiendo tal cual (ruta separada, sin tocar) — solo cambió a dónde apunta `root`. Ningún nav item del sidebar necesitó edición: "Inicio" ya usaba `root_path`.

## Validaciones

```bash
bin/dev
# → "/" ahora muestra el dashboard, no el styleguide
# → los 4 contadores coinciden con lo sembrado (bin/rails console: Role.count, etc.)
# → con el usuario admin sembrado (permiso roles.view): "Roles" es un link a /roles
# → con un usuario del rol "guest" (sin roles.view): "Roles" es texto plano, sin link
# → el chart de Actividad se ve con la paleta del tema, con el badge "Datos de ejemplo" visible
# → /styleguide sigue accesible directo por URL, sin cambios

bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

Los 4 contadores son agregados (un número), no listas — no exponen registros individuales a quien no tiene permiso de verlos. `policy(Role).index?` en la vista es solo para UX (evitar un link muerto); la protección real de `/roles` sigue siendo `RolePolicy` en el controlador, no algo que dependa de este dashboard.

## Mantenibilidad y compatibilidad futura

Cuando Setup 14 (Auditoría) exista, el chart de "Actividad" tiene un reemplazo obvio: cambiar el array armado a mano por `AuditLog.group_by_day(:created_at).count` (o el equivalente) y borrar el badge de "Datos de ejemplo" — nada más en la vista cambia. Setup 13 (Usuarios) puede sumar su propia tarjeta de stats al dashboard con el mismo patrón (`policy(User).index?` para decidir si es link).