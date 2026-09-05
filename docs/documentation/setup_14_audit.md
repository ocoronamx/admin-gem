# Setup 14 — Auditoría

## Objetivo

`Auditable` concern (hook genérico de create/update/destroy vía `ActiveModel::Dirty`) + modelo `AuditLog` propio — tal como fijaste en el ADR §8.5, en vez de una gema como `audited`. Se incluye en `User` y `Role`, y se expone una vista de solo lectura (`/audit_logs`) reusando `Filterable`/Pagy/`components/table` una vez más.

## Decisiones arquitectónicas

* **`changes_data` en JSONB**: tu propio `docs/conventions/database.md` ya nombra "metadata de auditoría" como el caso de uso legítimo de JSONB — es exactamente esto: forma variable (cada modelo audita atributos distintos), no consultable columna por columna.
* **`resource` polimórfico**, no una tabla de audit log por modelo — un solo lugar para consultar "qué pasó" sin importar qué se auditó.
* **Exclusión de columnas configurable por modelo (`audit_excludes`), no hardcodeada**: `password_digest` nunca puede aparecer en un diff — pero esa columna sensible es específica de `User`; el mecanismo tiene que ser genérico para que el próximo modelo auditable declare las suyas.
* **`Current.request` nuevo, para que el modelo pueda capturar IP/user-agent sin que el controlador se los pase a mano** en cada `save`. Mismo patrón que ya usás con `Current.session`/`Current.user`.
* **`destroy` audita un snapshot completo (`attributes`), no un diff** — después de destruido no hay "antes/después" que comparar, pero sí vale la pena guardar qué era ese registro.
* **Solo `audit_logs.view`, sin `.manage`**: es el primer recurso que rompe deliberadamente la convención `<recurso>.view`/`<recurso>.manage` de Setup 7 — un audit log no se edita ni se borra, así que un permiso de "manage" no significaría nada.
* **Nada de UI para filtrar por usuario o rango de fechas todavía** — se agrega `filterable_by action: :by_action` (match exacto, no ILIKE — `action` es un set fijo de valores) como demostración de que `Filterable` también sirve para eso, no solo para búsqueda parcial de texto.

## Alternativas consideradas

* **Gema `audited`** → descartada en el ADR; queda anotado ahí mismo que migrar a ella después, si hiciera falta compliance más pesado, es una migración de datos, no un rediseño — el esquema de `AuditLog` ya está pensado para eso (columnas equivalentes: actor, acción, recurso polimórfico, diff).
* **Loguear también `RolePermission`/`UserRole`** (cambios de permisos rol por rol) → no incluido todavía: agregaría mucho ruido (cada asignación de permiso es una fila) sin un caso de uso concreto que lo pida ahora. Se agrega el día que haga falta auditar "quién le dio tal permiso a tal rol" específicamente.
* **Vincular "Recurso" en la tabla a la página de edición real** (ej. link a `edit_user_path`) → descartado: solo `User` tiene página de edición hoy, y el manejo condicional por tipo de recurso no vale la pena todavía con un solo caso real.

## Comandos

```bash
bin/rails generate migration CreateAuditLogs
```

## Archivos

**db/migrate/…_create_audit_logs.rb** (edita la generada):

```ruby
class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true # nil = acción sin actor (seeds, jobs)
      t.references :resource, polymorphic: true, null: false
      t.string :action, null: false
      t.jsonb :changes_data, null: false, default: {}
      t.string :ip_address
      t.string :user_agent

      t.datetime :created_at, null: false
      # Sin updated_at: un audit log es inmutable — se crea, nunca se edita.
    end

    add_index :audit_logs, :action
  end
end
```

**app/models/current.rb** (edita):

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :request
  delegate :user, to: :session, allow_nil: true

  def ip_address
    request&.remote_ip
  end

  def user_agent
    request&.user_agent
  end
end
```

**app/controllers/application_controller.rb** — agrega el `before_action`:

```ruby
  before_action :set_theme
  before_action :set_sidebar_state
  before_action :set_current_request
```

```ruby
  # Expone el request actual en Current para que un modelo (ej. Auditable)
  # pueda registrar IP/user-agent sin que cada controller se lo pase a mano.
  def set_current_request
    Current.request = request
  end
```

**app/models/concerns/auditable.rb** (nuevo):

```ruby
# Hook genérico de auditoría vía ActiveModel::Dirty. Incluir en cualquier
# modelo que necesite dejar rastro de sus cambios — ver User/Role para el
# uso real, y audit_excludes para ocultar columnas sensibles del diff.
module Auditable
  extend ActiveSupport::Concern

  included do
    class_attribute :audit_excluded_columns, default: %w[created_at updated_at]

    after_create  { log_audit("create", saved_changes.except(*audit_excluded_columns)) }
    after_update  { log_audit("update", saved_changes.except(*audit_excluded_columns)) if audit_relevant_changes? }
    after_destroy { log_audit("destroy", attributes.except(*audit_excluded_columns)) }
  end

  class_methods do
    # Columnas que nunca deben aparecer en el diff — contraseñas, tokens,
    # cualquier cosa sensible. created_at/updated_at ya están excluidas
    # por defecto (puro ruido, no una decisión de negocio).
    def audit_excludes(*columns)
      self.audit_excluded_columns += columns.map(&:to_s)
    end
  end

  private

  def audit_relevant_changes?
    (saved_changes.keys - audit_excluded_columns).any?
  end

  def log_audit(action, changes_data)
    AuditLog.create!(
      user: Current.user,
      resource: self,
      action: action,
      changes_data: changes_data,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  end
end
```

**app/models/audit_log.rb** (nuevo):

```bash
touch app/models/audit_log.rb
```

```ruby
class AuditLog < ApplicationRecord
  belongs_to :user, optional: true # nil = acción sin actor (seeds, jobs)
  belongs_to :resource, polymorphic: true

  validates :action, presence: true

  scope :by_action, ->(value) { where(action: value) }
end
```

**app/models/user.rb** — agrega `include Auditable` y la exclusión:

```ruby
class User < ApplicationRecord
  include Auditable

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true

  audit_excludes :password_digest

  delegate :permits?, to: :role

  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :by_email, ->(value) { where("email_address ILIKE ?", "%#{sanitize_sql_like(value)}%") }

  def active?
    deactivated_at.nil?
  end
end
```

**app/models/role.rb** — agrega `include Auditable` (sin exclusiones extra, no tiene columnas sensibles):

```ruby
class Role < ApplicationRecord
  include Auditable

  # ... el resto queda igual
```

**app/policies/audit_log_policy.rb** (nuevo — vacío, mismo patrón que `RolePolicy`):

```bash
touch app/policies/audit_log_policy.rb
```

```ruby
class AuditLogPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end
end
```

**app/controllers/audit_logs_controller.rb** (nuevo):

```bash
bin/rails g controller AuditLogs
```

```ruby
class AuditLogsController < ApplicationController
  filterable_by action: :by_action

  def index
    authorize AuditLog
    scope = apply_filters(policy_scope(AuditLog)).order(created_at: :desc)
    @pagy, @audit_logs = pagy(:offset, scope)
  end
end
```

**app/helpers/audit_logs_helper.rb** (nuevo):

```bash
touch app/helpers/audit_logs_helper.rb
```

```ruby
module AuditLogsHelper
  # { "attr" => [viejo, nuevo] } → "attr: viejo → nuevo", separado por comas.
  # Suficiente para una tabla — no pretende ser un diff completo.
  def format_audit_changes(changes_data)
    return "—" if changes_data.blank?

    changes_data.map { |attr, value| "#{attr}: #{Array(value).join(' → ')}" }.join(", ")
  end

  def audit_action_badge(action)
    css = { "create" => "badge-success", "update" => "badge-info", "destroy" => "badge-error" }.fetch(action, "badge-ghost")
    content_tag :span, action, class: "badge badge-sm #{css}"
  end
end
```

**config/routes.rb** — agrega:

```ruby
  resources :audit_logs, only: :index
```

**app/views/audit_logs/index.html.erb** (nuevo):

```bash
touch app/views/audit_logs/index.html.erb
```

```erb
<% content_for :title, "Auditoría" %>

<h1 class="text-2xl font-semibold mb-4">Auditoría</h1>

<%= render(layout: "components/card") do %>
  <%= render "components/table",
        records: @audit_logs,
        empty_title: "Sin actividad todavía",
        columns: [
          { label: "Usuario", format: ->(log) { log.user&.email_address || "Sistema" } },
          { label: "Acción", format: ->(log) { audit_action_badge(log.action) } },
          { label: "Recurso", format: ->(log) { "#{log.resource_type} ##{log.resource_id}" } },
          { label: "Cambios", format: ->(log) { format_audit_changes(log.changes_data) } },
          { label: "Fecha", format: ->(log) { l(log.created_at, format: :short) } },
          { label: "IP", attribute: :ip_address }
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

**app/views/layouts/_sidebar.html.erb** — agrega el ítem, después de "Usuarios":

```ruby
    { label: "Usuarios", icon: :users, path: users_path, available: true },
    { label: "Auditoría", icon: :bars_3, path: audit_logs_path, available: true },
```

(`bars_3` ya existe en `IconsHelper` per el styleguide — si preferís un ícono más específico tipo "documento/historial" habría que agregarlo, decime si querés que lo sume.)

**db/seeds.rb** — agrega el permiso nuevo a la lista:

```ruby
permission_keys = %w[users.view users.manage roles.view roles.manage audit_logs.view]
```

**docs/conventions/auditing.md** (nuevo):

```bash
touch docs/conventions/auditing.md
```

```markdown
# Convenciones de auditoría — admin-gem

## Cómo hacer un modelo auditable
`include Auditable` — registra automáticamente create/update/destroy con el
diff de `ActiveModel::Dirty`. Si el modelo tiene columnas sensibles, excluilas:

```ruby
class User < ApplicationRecord
  include Auditable
  audit_excludes :password_digest
end
```

`created_at`/`updated_at` ya están excluidas por defecto — son ruido, no una
decisión de negocio.

## Qué queda registrado
`AuditLog`: quién (`user`, nil si fue el sistema — seeds, jobs), qué pasó
(`action`: create/update/destroy), sobre qué (`resource` polimórfico),
el diff (`changes_data`, jsonb), IP y user-agent (vía `Current.request`,
seteado en `ApplicationController#set_current_request`).

## Solo `.view`, nunca `.manage`
Un audit log no se edita ni se borra desde el panel — el permiso `manage`
no tendría significado acá. Es la única excepción a la convención
`<recurso>.view`/`<recurso>.manage` de `docs/conventions/authorization.md`.

## Qué no cubre esta fase (a propósito)
- Auditar los join models (`UserRole`, `RolePermission`) — se agrega si aparece
  un caso real de "quién le dio tal permiso a tal rol".
- Restauración point-in-time — si hace falta compliance más pesado, el ADR
  ya anota migrar a la gema `audited` como mejora incremental, no como base.
```

**spec/models/concerns/auditable_spec.rb** (nuevo):

```bash
mkdir spec/models/concerns
touch spec/models/concerns/auditable_spec.rb
```

```ruby
require "rails_helper"

RSpec.describe Auditable do
  let(:role) { create(:role) }

  it "registra un audit log al crear" do
    expect { create(:user, role: role) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.action).to eq("create")
    expect(log.resource).to be_a(User)
  end

  it "registra el diff al actualizar, sin exponer password_digest" do
    user = create(:user, role: role)

    expect { user.update!(email_address: "nuevo@example.com") }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.action).to eq("update")
    expect(log.changes_data).to have_key("email_address")
    expect(log.changes_data).not_to have_key("password_digest")
  end

  it "no registra nada si no hubo cambios reales" do
    user = create(:user, role: role)

    expect { user.save! }.not_to change(AuditLog, :count)
  end
end
```

**spec/requests/audit_logs_spec.rb** (nuevo):

```bash
touch spec/requests/audit_logs_spec.rb
```

```ruby
require "rails_helper"

RSpec.describe "AuditLogs", type: :request do
  describe "GET /audit_logs" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get audit_logs_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
```

**docs/documentation/setup_99_TODO.md** — mueve Setup 14 a hecho, Setup 15 a CURRENT:

```markdown
* Setup 13 — Usuarios                        (módulo de referencia)
* Setup 14 — Auditoría                       (Auditable concern + AuditLog propio)

## CURRENT:
* Setup 15 — Testing                         (RSpec, factories, qué probar y qué no)
```

## Verificación de consistencia

`AuditLogsController` reusa `Filterable`/`policy_scope`/`components/table`/Pagy sin ninguna pieza nueva de infraestructura — cuarto controlador seguido que se arma así. `password_digest` nunca puede filtrarse: está excluido a nivel de modelo, no a nivel de vista, así que ningún futuro consumidor de `AuditLog` (una API, un export) puede exponerlo por accidente.

## Validaciones

```bash
bin/rails db:migrate
bin/rails db:seed

bin/rails console
# > User.first.update!(email_address: "otro@example.com")
# > AuditLog.last.changes_data # => {"email_address"=>["viejo@...", "otro@example.com"]}
# > AuditLog.last.changes_data.key?("password_digest") # => false

bin/dev
# → "Auditoría" aparece en el sidebar
# → editá un usuario, desactivalo/reactivalo, editá un rol si tenés forma de
#   hacerlo — cada acción debería aparecer en /audit_logs con el diff correcto
# → filtrá por acción (create/update/destroy)
# → con un usuario sin audit_logs.view: "Auditoría" no debería estar en el
#   sidebar del todo (nav item no condicionado a permiso todavía — ver nota
#   de Seguridad abajo) pero /audit_logs sí debería rechazarlo

bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

`password_digest` está excluido a nivel de `User` (modelo), no confiado a que cada vista/reporte recuerde no mostrarlo. Ningún dato de auditoría se expone sin pasar por `AuditLogPolicy` — mismo mecanismo de `authorize`/`policy_scope` que todo lo demás, no una excepción.

**Nota, no bloqueante**: el ítem "Auditoría" del sidebar quedó con `available: true` fijo, igual que "Roles"/"Usuarios" — no se oculta para quien no tiene `audit_logs.view` (haría clic y rebotaría con el mensaje de permiso, pero vería el link). Es el mismo comportamiento que ya tenían Roles/Usuarios desde que se agregaron — no es una regresión de esta fase, pero como ahora son tres ítems así, si te interesa que el sidebar oculte lo que no podés usar en vez de dejarte chocar contra el permiso, decime y lo resuelvo (sería un solo cambio en `_sidebar.html.erb`, consultando `policy(...).index?` por ítem en vez del `available:` estático actual).

## Mantenibilidad y compatibilidad futura

Setup 15 (Testing) hereda una base de specs reales para lo más sensible (permisos, autoprotección, ahora auditoría) y pending stubs para lo puramente generado — ya sabe qué "sí probar" mirando este historial. Cualquier modelo futuro que necesite rastro de cambios es una línea (`include Auditable`) más, si corresponde, `audit_excludes`.
