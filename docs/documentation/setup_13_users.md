# Setup 13 — Usuarios (módulo de referencia)

## Objetivo

CRUD completo de usuarios: listar (con `Filterable`/Pagy/tabla reutilizable), crear, editar, y desactivar/reactivar — nunca borrar. Implementa el soft-delete que `docs/conventions/database.md` dejó anotado desde Setup 3 ("Ver Usuarios como referencia") y cierra esa promesa para todo módulo futuro.

## Decisiones arquitectónicas

* **Soft-delete real, no `destroy`**: `deactivated_at:datetime` (nil = activo). No hay ruta ni acción de borrado físico en el panel — quien "elimina" a alguien en realidad desactiva. Evita perder el historial (sesiones, futura auditoría en Setup 14) y respeta integridad referencial sin `dependent: :nullify` improvisado en cada asociación.
* **`toggle_active` como una sola acción reversible**, no `activate`/`deactivate` separadas: es el mismo botón cambiando de texto según el estado — menos rutas, menos policies que mantener sincronizadas.
* **Desactivar corta la sesión al instante, no solo bloquea el próximo login**: agrego el chequeo de `active?` en `Authentication#find_session_by_cookie` (no solo en `SessionsController#create`). Sin esto, alguien desactivado con una cookie de sesión válida seguiría usando el panel hasta que expire.
* **El mensaje de login no distingue "no existe" de "está desactivado"**: mismo criterio que ya usaste en Setup 6 para el email de recuperación de contraseña — no le des a un atacante una forma de enumerar cuentas desactivadas.
* **Autoprotección vía policy (`record != user`), no un `if` disperso en el controlador**: `UserPolicy#toggle_active?` deniega desactivarte a vos mismo. Mismo patrón que ya usás para todo lo demás — la regla vive en un solo lugar, y la vista la consulta (`policy(user).toggle_active?`) para directamente no mostrar el botón, no solo para bloquear el submit.
* **Nadie cambia su propio rol, ni siquiera un admin**: se corta en dos capas — la vista no renderiza el `<select>` de rol cuando editás tu propia cuenta, y el controlador igual descarta `role_id` de los params si `@user == Current.user`, por si alguien arma el request a mano.
* **Acá sí hace falta `permit`**: como quedó pendiente desde la charla de `Filterable` en Setup 10 — `create`/`update` sí hacen mass-assignment real sobre un modelo (`User.new(user_params)`), así que strong params es la herramienta correcta acá, a diferencia del filtrado de tablas.

## Alternativas consideradas

* **Borrado físico con `dependent: :nullify` en sesiones** → descartado: pierde la posibilidad de auditar qué pasó con esa cuenta (relevante para Setup 14).
* **Bloquear también la edición completa de tu propia cuenta** (no solo el rol) → descartado: un admin gestionándose a sí mismo (cambiar su email/contraseña desde el panel) es un caso de uso legítimo; solo el rol es lo que puede autobloquear el acceso.
* **Proteger "el último usuario con `users.manage`" contra desactivación** → NO implementado, a propósito, mismo criterio que Setup 7 con roles: detectar "sos el último" de forma genérica pedís contar usuarios activos por permiso en cada intento de desactivar — no hay todavía un caso real que lo justifique más allá de la autoprotección directa (que sí cubre el caso más común: desactivarte sin querer a vos mismo). Queda anotado para revisar si aparece un caso real.
* **`show` además de `edit`** → descartado: no hay ningún dato adicional que mostrar fuera del form — `edit` ya cumple ese rol, como en la mayoría de paneles admin reales.

## Comandos

```bash
bin/rails generate migration AddDeactivatedAtToUsers deactivated_at:datetime
```

## Archivos

**db/migrate/…_add_deactivated_at_to_users.rb** (edita la generada):

```ruby
class AddDeactivatedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    # nil = activo; con fecha = desactivado (ver docs/conventions/database.md,
    # sección "Soft delete" — este es el módulo de referencia que prometía).
    add_column :users, :deactivated_at, :datetime
  end
end
```

**app/models/user.rb** (edita):

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true

  delegate :permits?, to: :role

  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }

  def active?
    deactivated_at.nil?
  end
end
```

**app/policies/user_policy.rb** (nuevo):

```bash
bin/rails generate pundit:policy User
```

```ruby
class UserPolicy < ApplicationPolicy
  # No podés desactivarte/reactivarte a vos mismo — evita autobloquearte el
  # acceso por accidente. La vista consulta esto para directamente no mostrar
  # el botón (ver app/views/users/_actions.html.erb).
  def toggle_active?
    permitted?(:manage) && record != user
  end

  class Scope < ApplicationPolicy::Scope
  end
end
```

**app/controllers/users_controller.rb** (nuevo):

```bash
bin/rails generate controller users
```

```ruby
class UsersController < ApplicationController
  filterable_by email: :by_email

  before_action :set_user, only: %i[ edit update toggle_active ]

  def index
    authorize User
    scope = apply_filters(policy_scope(User)).order(:email_address)
    @pagy, @users = pagy(:offset, scope)
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      redirect_to users_path, notice: "Usuario creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    # Nadie cambia su propio rol desde acá, ni siquiera un admin — la vista ya
    # no muestra el <select> para ese caso, esto es la segunda capa.
    attrs = @user == Current.user ? user_params.except(:role_id) : user_params

    if @user.update(attrs)
      redirect_to users_path, notice: "Usuario actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    authorize @user

    if @user.active?
      @user.update!(deactivated_at: Time.current)
      @user.sessions.destroy_all
      notice = "Usuario desactivado."
    else
      @user.update!(deactivated_at: nil)
      notice = "Usuario reactivado."
    end

    redirect_to users_path, notice: notice
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :role_id)
  end
end
```

**app/models/role.rb** — agrega el scope de filtro que faltaba (mismo patrón que `by_name`/`by_key`, ahora para Usuarios):

```ruby
# en User, no en Role — agregalo en app/models/user.rb junto a los scopes de arriba:
scope :by_email, ->(value) { where("email_address ILIKE ?", "%#{sanitize_sql_like(value)}%") }
```

**config/routes.rb** — reemplaza:

```ruby
  resources :roles, only: :index
  resources :users, except: :show do
    member do
      patch :toggle_active
    end
  end
```

**app/controllers/concerns/authentication.rb** — agrega el corte inmediato de sesión:

```ruby
    def find_session_by_cookie
      return unless cookies.signed[:session_id]

      session = Session.find_by(id: cookies.signed[:session_id])
      return unless session&.user&.active?

      # Throttleado a 1 escritura/hora por sesión — no en cada request.
      session.tap { |s| s.touch(:updated_at) if s.updated_at < 1.hour.ago }
    end
```

**app/controllers/sessions_controller.rb** — edita `create`:

```ruby
  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user&.active?
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Correo o contraseña incorrectos."
    end
  end
```

**app/views/users/_form.html.erb** (nuevo):

```bash
touch app/views/users/_form.html.erb
```

```erb
<%= form_with model: user, class: "space-y-1" do |form| %>
  <%= form.email_field :email_address, label: "Correo", required: true, autofocus: true,
        autocomplete: "email" %>

  <%= form.password_field :password,
        label: user.new_record? ? "Contraseña" : "Nueva contraseña",
        required: user.new_record?, maxlength: 72, autocomplete: "new-password",
        hint: user.new_record? ? "Mínimo 12 caracteres." : "Dejar en blanco para no cambiarla." %>

  <%= form.password_field :password_confirmation, label: "Repite la contraseña",
        required: user.new_record?, maxlength: 72, autocomplete: "new-password" %>

  <% if user == Current.user %>
    <div class="fieldset w-full">
      <label class="label">Rol</label>
      <p class="text-sm text-base-content/60">No podés cambiar tu propio rol desde acá.</p>
    </div>
  <% else %>
    <%= form.select :role_id, Role.order(:name).pluck(:name, :id), { label: "Rol" }, { include_blank: false } %>
  <% end %>

  <%= form.submit user.new_record? ? "Crear usuario" : "Guardar cambios", class: "btn btn-primary w-full mt-2" %>
<% end %>
```

**app/views/users/_actions.html.erb** (nuevo):

```bash
touch app/views/users/_actions.html.erb
```

```erb
<div class="flex items-center gap-2 justify-end">
  <%= link_to "Editar", edit_user_path(user), class: "link link-hover text-sm" %>
  <% if policy(user).toggle_active? %>
    <%= button_to (user.active? ? "Desactivar" : "Reactivar"), toggle_active_user_path(user), method: :patch,
          data: { turbo_confirm: "¿#{user.active? ? "Desactivar" : "Reactivar"} a #{user.email_address}?" },
          class: "btn btn-ghost btn-xs #{"text-error" if user.active?}" %>
  <% end %>
</div>
```

**app/views/users/index.html.erb** (nuevo):

```bash
touch app/views/users/index.html.erb
```

```erb
<% content_for :title, "Usuarios" %>

<h1 class="text-2xl font-semibold mb-4">Usuarios</h1>

<%= render(layout: "components/card") do %>
  <div class="flex items-center justify-between mb-4 gap-3">
    <%= form_with url: users_path, method: :get do |form| %>
      <div class="w-64">
        <%= form.text_field :email, label: "Correo", value: params.dig(:q, :email),
              placeholder: "Buscar...", name: "q[email]" %>
      </div>
    <% end %>
    <% if policy(User).new? %>
      <%= render "components/button", text: "Nuevo usuario", href: new_user_path, variant: :primary %>
    <% end %>
  </div>

  <%= render "components/table",
        records: @users,
        empty_title: "Sin usuarios que coincidan",
        columns: [
          { label: "Correo", attribute: :email_address },
          { label: "Rol", format: ->(u) { u.role.name } },
          { label: "Estado", format: ->(u) {
              u.active? ? content_tag(:span, "Activo", class: "badge badge-success badge-sm")
                        : content_tag(:span, "Desactivado", class: "badge badge-ghost badge-sm")
            } },
          { label: "", format: ->(u) { render "users/actions", user: u } }
        ] %>

  <div class="flex items-center justify-between mt-4">
    <p class="text-sm text-base-content/60"><%== @pagy.info_tag %></p>
    <%== @pagy.series_nav(
      nav_extra: 'class="join"', link_extra: 'class="join-item btn btn-sm"',
      active_link_extra: 'class="join-item btn btn-sm btn-active"'
    ) %>
  </div>
<% end %>
```

**app/views/users/new.html.erb** (nuevo):

```bash
touch app/views/users/new.html.erb
```

```erb
<% content_for :title, "Nuevo usuario" %>

<h1 class="text-2xl font-semibold mb-4">Nuevo usuario</h1>

<%= render(layout: "components/card") do %>
  <%= render "form", user: @user %>
<% end %>
```

**app/views/users/edit.html.erb** (nuevo):

```bash
touch app/views/users/edit.html.erb
```

```erb
<% content_for :title, "Editar usuario" %>

<h1 class="text-2xl font-semibold mb-4">Editar usuario</h1>

<%= render(layout: "components/card") do %>
  <%= render "form", user: @user %>
<% end %>
```

**app/views/layouts/_sidebar.html.erb** — habilita el ítem:

```ruby
    { label: "Usuarios", icon: :users, path: users_path, available: true },
```

**db/seeds.rb** — agrega dentro del bloque `if User.none?`, después del usuario "guest":

```ruby
  guest_role = Role.find_by!(key: "guest")
  User.create!(email_address: "guest@example.com", password: "password123456", role: guest_role)

  # Un usuario desactivado de entrada, para ver el estado "Desactivado" sin
  # tener que desactivar a alguien a mano primero.
  User.create!(email_address: "desactivado@example.com", password: "password123456",
               role: guest_role, deactivated_at: Time.current)
```

**docs/conventions/database.md** — reemplaza la sección "Soft delete" (cierra la referencia pendiente desde Setup 3):

```markdown
## Soft delete
No hay mecanismo genérico — cada módulo que necesite "desactivar sin borrar" añade
su propia columna explícita y sus propios scopes. Referencia real: Usuarios (Setup 13):
- Columna `deactivated_at:datetime`, nil = activo.
- `scope :active` / `scope :deactivated` en el modelo, método `active?`.
- La sesión de un usuario desactivado se corta en el próximo request, no solo
  se bloquea el próximo login (`Authentication#find_session_by_cookie`).
- Nunca un mensaje que distinga "no existe" de "está desactivado" en el login.
```

**docs/conventions/authorization.md** — agrega una sección corta:

```markdown
## Autoprotección ("no podés hacerte esto a vos mismo")
Cuando una acción no debería poder aplicarse a la propia cuenta (desactivarte,
cambiarte el rol), la regla vive en la policy (`record != user`), nunca en un
`if` suelto en el controlador. La vista consulta la policy para directamente
no mostrar la opción — no solo para bloquear el submit. Ver `UserPolicy#toggle_active?`.
```

**spec/factories/permissions.rb** — sin cambios (ya cubre esto), pero agrega a **spec/factories/roles.rb** si tu versión no setea `key` con secuencia (revisá — si ya lo hace, ignorá este bloque):

```ruby
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Rol #{n}" }
    sequence(:key) { |n| "rol_#{n}" }
  end
end
```

**spec/policies/user_policy_spec.rb** (nuevo):

```ruby
require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  describe UserPolicy do
    subject { described_class }

    let(:role) { create(:role, name: "Editor", key: "editor") }
    let(:user) { create(:user, role: role) }
    let(:other_user) { create(:user, role: role) }

    context "con permiso users.manage" do
      before { role.permissions << create(:permission, key: "users.manage") }

      it "permite desactivar a otro usuario" do
        expect(described_class.new(user, other_user)).to permit_action(:toggle_active?)
      end

      it "no permite desactivarse a sí mismo" do
        expect(described_class.new(user, user)).not_to permit_action(:toggle_active?)
      end
    end

    context "sin permiso users.manage" do
      it "no permite desactivar a nadie" do
        expect(described_class.new(user, other_user)).not_to permit_action(:toggle_active?)
      end
    end
  end
end
```

**spec/requests/users_spec.rb** (nuevo):

```ruby
require "rails_helper"

RSpec.describe "Users", type: :request do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: user.password }
  end

  let(:manage_role) { create(:role, name: "Admin", key: "admin_test") }
  let(:admin) { create(:user, role: manage_role, password: "contraseña-larga-123") }

  before { manage_role.permissions << create(:permission, key: "users.manage") }

  describe "GET /users" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get users_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "PATCH /users/:id/toggle_active" do
    it "desactiva a otro usuario y corta su sesión" do
      sign_in(admin)
      target = create(:user, role: manage_role, password: "contraseña-larga-123")

      patch toggle_active_user_path(target)
      target.reload

      expect(target.active?).to be false
      expect(target.sessions.count).to eq(0)
    end

    it "impide desactivarse a sí mismo" do
      sign_in(admin)

      patch toggle_active_user_path(admin)

      expect(response).to redirect_to(root_path)
      expect(admin.reload.active?).to be true
    end
  end

  describe "un usuario desactivado" do
    it "no puede iniciar sesión" do
      inactive = create(:user, role: manage_role, password: "contraseña-larga-123", deactivated_at: Time.current)

      sign_in(inactive)

      expect(response).to redirect_to(new_session_path)
    end
  end
end
```

**docs/documentation/setup_99_TODO.md** — mueve Setup 13 a hecho, Setup 14 a CURRENT:

```markdown
* Setup 12 — Dashboard                       (demo data, claramente marcada)
* Setup 13 — Usuarios                        (módulo de referencia)

## CURRENT:
* Setup 14 — Auditoría                       (Auditable concern + AuditLog propio)

## TODO:
* Setup 15 — Testing                         (RSpec, factories, qué probar y qué no)
```

## Verificación de consistencia

`Filterable`, `components/table`, `AdminFormBuilder` y `authorize` + `policy_scope` juntos en `index` — cero piezas nuevas de infraestructura, solo las que ya existían aplicadas al primer recurso con formulario completo. `users.view`/`users.manage` ya estaban sembrados desde Setup 7, sin tocar `permission_keys`.

## Validaciones

```bash
bin/rails db:migrate
bin/rails db:seed

bin/dev
# → "Usuarios" en el sidebar ya no dice "pronto"
# → con el admin sembrado: lista los usuarios, "Nuevo usuario" visible
# → creá un usuario nuevo, asignale un rol sin users.manage: no ve "Usuarios" en el sidebar
# → editá tu propia cuenta: el campo Rol no aparece, aparece el aviso en su lugar
# → en la fila de tu propio usuario: no aparece el botón Desactivar/Reactivar
# → desactivá a otro usuario (con confirm de tu modal, no el nativo del navegador)
#   e intentá iniciar sesión como ese usuario: "Correo o contraseña incorrectos"
#   (mismo mensaje que un usuario inexistente — no delata que existe)
# → con ese usuario ya logueado en otra pestaña antes de desactivarlo: al
#   siguiente click, la sesión se corta y pide loguearse de nuevo
# → filtrá por correo: funciona igual que en Roles

bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

El mensaje de login no distingue cuenta inexistente de cuenta desactivada — evita enumeración. Desactivar borra las sesiones activas de esa cuenta de inmediato (no solo bloquea logins futuros); aun si no las borrara, `find_session_by_cookie` ya corta el acceso en el próximo request. La autoprotección (`record != user`) vive en la policy, no en cada vista por separado, así que cualquier acción futura sobre `User` que también necesite ese resguardo lo hereda con la misma línea.

## Mantenibilidad y compatibilidad futura

Setup 14 (Auditoría) tiene ahora un evento real y con sentido para el primer `AuditLog`: quién desactivó/reactivó a quién y cuándo — `toggle_active` es del tamaño justo para engancharle un `after_action` o un callback de modelo sin rediseñar nada. El patrón `deactivated_at` + scopes queda documentado en `docs/conventions/database.md` para que el próximo módulo que necesite "borrado suave" no tenga que redescubrirlo.