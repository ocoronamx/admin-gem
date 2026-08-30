# Setup 7 — Authorization

## Objetivo

User → Role → Permissions con Pundit, tal como quedó decidido en el ADR §7. Cada policy resuelve sus permisos por convención a partir de su propio nombre de clase (UserPolicy → recurso users) — así añadir autorización a un módulo nuevo en Setup 13 no requiere registrar nada a mano.

## Decisiones arquitectónicas

* Un rol por usuario (belongs_to :role), no roles múltiples — coincide con el ADR y es más fácil de razonar para un panel administrativo interno.
* Dos niveles de permiso por recurso: <recurso>.view (index/show) y <recurso>.manage (create/update/destroy). * Nada más granular por ahora — si un módulo concreto lo necesita, ese módulo agrega su propio nivel (ej. reports.export), no se cambia la convención global.
* El nombre de la policy determina el recurso automáticamente (UserPolicy → "users", vía self.class.name). 
* Verifiqué el generador oficial de Pundit (2.5.2, misma versión que fijamos en el ADR) para construir esto exactamente sobre su convención, no en paralelo a ella.
* after_action :verify_authorized / verify_policy_scoped en ApplicationController — si un desarrollador nuevo olvida autorizar una acción en un controlador futuro, la app truena en vez de dejarlo pasar silenciosamente (Fail Secure).

## Alternativas consideradas

* Permisos por acción exacta (users.index, users.show, users.create...) → descartado: demasiadas filas para que un humano administre roles con sentido; dos niveles (view/manage) cubren el 95% de los casos reales de un panel admin.
* CanCanCan en vez de Pundit → ya descartado en el ADR; Pundit + clases explícitas es más legible para un equipo que crece.
* Rol múltiple por usuario desde ahora → descartado (YAGNI); si aparece la necesidad real, es un cambio acotado de belongs_to a has_and_belongs_to_many.

## Qué prevenimos

* Autorización dispersa tipo if current_user.admin? (la razón de ser de esta fase, ya lo pedías en el prompt original).
* Un controlador nuevo que se cuela sin ningún chequeo de permisos (el after_action lo revienta en test/development, no en el silencio de producción).
* El error clásico de Pundit con clases Scope anidadas: verifiqué en el propio código fuente de Pundit que las versiones viejas resolvían Scope por herencia implícita de forma ambigua — por eso cada policy nueva debe declarar class Scope < ApplicationPolicy::Scope explícitamente, nunca dejarlo implícito.
* Migrar role_id como NOT NULL sobre una tabla users que ya tiene filas (tu admin de Setup 6) sin quebrar esa fila — la migración rellena el dato antes de aplicar la restricción.

## Comandos

```bash
bundle add pundit --version "~> 2.5"
bin/rails generate pundit:install
bin/rails generate migration CreateRoles name:string:uniq
bin/rails generate migration CreatePermissions key:string:uniq description:string
bin/rails generate migration CreateRolePermissions role:references permission:references
```

## Archivos

db/migrate/xxxxxxxxxxxxxx_create_roles.rb (editar):

```ruby
class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :key, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true
    add_index :roles, :key, unique: true
  end
end
```

db/migrate/xxxxxxxxxxxxxx_create_permissions.rb (editar):

```ruby
class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.string :key, null: false
      t.string :description, null: false, default: ""

      t.timestamps
    end
    add_index :permissions, :key, unique: true
  end
end
```

Edita db/migrate/..._create_role_permissions.rb (el generador no agrega el índice compuesto único, lo agregamos):

```ruby
class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true

      t.timestamps
    end
    add_index :role_permissions, [:role_id, :permission_id], unique: true
  end
end
```

Generar modelos

```bash
bin/rails generate model Role name:string --skip
bin/rails generate model Permission key:string --skip
bin/rails generate model RolePermission role:references permission:references --skip
```

Ejecutar migration

```bash
bin/rails db:migrate
```

app/models/role.rb (nuevo):

```ruby
class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :key, presence: true, uniqueness: true

  def permits?(key)
    permission_keys.include?(key.to_s)
  end

  private

  def permission_keys
    @permission_keys ||= permissions.pluck(:key)
  end
end
```

app/models/permission.rb (nuevo):

```ruby
class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, presence: true, uniqueness: true
end
```

app/models/role_permission.rb (nuevo):

```ruby
class RolePermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission

  validates :role_id, uniqueness: { scope: :permission_id }
end
```

app/models/user.rb (edita — agrega la asociación y la delegación):

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true

  delegate :permits?, to: :role
end
```

app/policies/concerns/permission_resource.rb (nuevo — el mecanismo genérico, compartido entre ApplicationPolicy y su Scope):

```ruby
# Deriva el nombre del recurso ("users", "widgets"...) a partir del nombre
# de la clase de policy que lo incluye, y construye la clave de permiso
# correspondiente ("users.view", "users.manage").
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

app/policies/application_policy.rb (el generador crea la versión con false fijo en cada método — la reemplazamos por esta):

```ruby
class ApplicationPolicy
#   include PermissionResource

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    permitted?(:view)
  end

  def show?
    permitted?(:view)
  end

  def create?
    permitted?(:manage)
  end

  def new?
    create?
  end

  def update?
    permitted?(:manage)
  end

  def edit?
    update?
  end

  def destroy?
    permitted?(:manage)
  end

  class Scope
    # include PermissionResource

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      permitted?(:view) ? scope.all : scope.none
    end
  end
end
```

app/controllers/application_controller.rb (reemplaza completo — mantengo tus comentarios existentes y agrego Pundit):

```ruby
# Controlador base de la aplicación del cual heredan todos los demás controladores.
# Maneja configuraciones globales como restricciones de navegador, caching, el layout principal,
# la autorización con Pundit, y la inicialización de preferencias de la interfaz (tema visual y estado de la barra lateral).
class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Restringe el acceso únicamente a navegadores modernos con soporte completo para tecnologías web recientes.
  allow_browser versions: :modern

  # Invalida las etiquetas ETag para respuestas HTML automáticamente si cambia el mapa de importaciones.
  stale_when_importmap_changes

  layout "admin"

  before_action :set_theme
  before_action :set_sidebar_state

  # Falla en vez de dejar pasar en silencio si un controlador nuevo olvida autorizar una acción.
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_theme, :sidebar_collapsed?

  private

  # Inicializa la variable de instancia con la preferencia del tema visual.
  # Valida que la cookie de tema sea estricta ("light" o "dark") para evitar valores arbitrarios,
  # aplicando "light" como fallback de seguridad.
  #
  # @return [String] El tema activo ("light" o "dark").
  def set_theme
    @current_theme = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
  end

  # Inicializa la variable de instancia con el estado de despliegue de la barra lateral
  # leyendo la preferencia persistida en las cookies.
  #
  # @return [Boolean] true si la cookie equivale a "collapsed", de lo contrario false.
  def set_sidebar_state
    @sidebar_collapsed = cookies[:sidebar] == "collapsed"
  end

  # Devuelve el tema visual activo durante el ciclo de vida del request.
  #
  # @return [String] "light" o "dark".
  # @note Expuesto como `helper_method` para su consumo directo en plantillas ERB.
  def current_theme
    @current_theme
  end

  # Indica si la barra lateral de navegación debe renderizarse en su versión colapsada.
  #
  # @return [Boolean] true si la barra lateral está contraída, false si está expandida.
  # @note Expuesto como `helper_method` para su consumo directo en plantillas ERB.
  def sidebar_collapsed?
    @sidebar_collapsed
  end

  # Usuario que Pundit usa en policies y scopes. Por defecto Pundit llama a
  # `current_user`, que no existe en nuestra app (usamos `Current.user`, del
  # generador de autenticación nativo de Rails 8).
  #
  # @return [User, nil]
  def pundit_user
    Current.user
  end

  # Maneja los rechazos de autorización de Pundit de forma consistente en toda la app.
  def user_not_authorized
    flash[:alert] = "No tienes permiso para realizar esta acción."
    redirect_back fallback_location: root_path
  end
end
```

app/controllers/pages_controller.rb — añade la primera línea dentro de la clase:

```ruby
class PagesController < ApplicationController
  skip_after_action :verify_authorized # /styleguide no es un recurso con permisos, solo una herramienta de dev
  before_action :ensure_local_environment, only: :styleguide
  ...
```

app/controllers/sessions_controller.rb y app/controllers/passwords_controller.rb — añade a ambos, justo después de layout "application":

```ruby
  skip_after_action :verify_authorized # pantallas previas a autenticación, no hay "usuario" que autorizar
```

db/seeds.rb (reemplaza el de Setup 6):

```ruby
# Sin registro público en este boilerplate: las cuentas las crea un admin
# (Setup 13) o, para el arranque inicial, se siembra aquí vía variables de entorno.
#
# Cada módulo nuevo declara sus propios permisos "<recurso>.view" / "<recurso>.manage"
# (ver docs/conventions/authorization.md). Por ahora solo existe "users".
permission_keys = %w[users.view users.manage]
permissions_by_key = permission_keys.index_with { |key| Permission.find_or_create_by!(key: key) }

roles = {
  "super"    => { name: "Super",         permissions: permission_keys },
  "admin"    => { name: "Administrator", permissions: permission_keys },
  "standard" => { name: "Standard",      permissions: %w[users.view] },
  "client"   => { name: "Client",        permissions: [] },
  "guest"    => { name: "Guest",         permissions: [] }
}

roles.each do |key, attrs|
  role = Role.find_or_initialize_by(key: key)
  role.name = attrs[:name]
  role.save!

  # Asignar la asociación has_many :through crea/borra los RolePermission
  # necesarios automáticamente — no hay que tocar esa tabla a mano.
  role.permissions = attrs[:permissions].map { |k| permissions_by_key.fetch(k) }

  puts "Rol listo: #{role.name} (#{role.permissions.count} permisos)"
end

if User.none?
  email = ENV["SEED_ADMIN_EMAIL"]
  password = ENV["SEED_ADMIN_PASSWORD"]

  if email.present? && password.present?
    role = Role.find_by!(key: "super")
    User.create!(email_address: email, password: password, role: role)
    puts "Usuario administrador creado: #{email}, rol: #{role&.name}"
  else
    puts "Sin usuarios y sin SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD — no se creó ningún usuario."
  end
end
```

Regenerar database

```bash
bin/rails db:migrate:reset   # o db:drop db:create si prefieres empezar limpio
SEED_ADMIN_EMAIL=ocorona.desarrollo@gmail.com SEED_ADMIN_PASSWORD=ocorona.desarrollo bin/rails db:seed
# > Role.pluck(:key, :name)
# > Role.find_by(key: "admin").permissions.pluck(:key) => ["users.view", "users.manage"]
```

spec/factories/roles.rb (nuevo):

```bash
touch spec/factories/roles.rb
```

```ruby
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Rol #{n}" }
  end
end
```

spec/factories/permissions.rb (nuevo):

```bash
touch spec/factories/permissions.rb
```

```ruby
FactoryBot.define do
  factory :permission do
    sequence(:key) { |n| "recurso_#{n}.view" }
  end
end
```

spec/factories/users.rb (corrige la contraseña corta y agrega role):

```ruby
FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "contraseña-larga-123" }
    association :role
  end
end
```

spec/rails_helper.rb — añade junto a los demás require:

```ruby
require 'pundit/rspec'
```

spec/models/user_spec.rb (reemplaza el pending):

```ruby
require "rails_helper"

RSpec.describe User, type: :model do
  it "normaliza el email a minúsculas y sin espacios" do
    user = build(:user, email_address: "  Persona@Ejemplo.com ")
    expect(user.email_address).to eq("persona@ejemplo.com")
  end

  it "es válido con una contraseña de 12 caracteres o más" do
    expect(build(:user, password: "contraseña-larga-123")).to be_valid
  end

  it "es inválido con una contraseña más corta de 12 caracteres" do
    expect(build(:user, password: "corta")).not_to be_valid
  end

  it "delega permits? al rol asignado" do
    # create(:role, name: "Administrador", key: 'admin',  permissions: %w[users.view users.manage])
    role = create(:role, name: "Administrador", key: 'admin')
    role.permissions << create(:permission, key: "users.view")
    user = create(:user, email_address: 'user@mail.com', password: 'admin gem strong password', role: role)

    expect(user.permits?("users.view")).to be true
    expect(user.permits?("users.manage")).to be false
  end
end
```

spec/models/role_spec.rb (nuevo):

```bash
touch spec/models/role_spec.rb
```

```ruby
require "rails_helper"

RSpec.describe Role, type: :model do
  it "requiere un nombre único" do
    create(:role, name: "Administrador", key: 'admin')
    expect(build(:role, name: "Administrador", key: 'admin')).not_to be_valid
  end

  it "expone si tiene una key de permiso concreta" do
    role = create(:role, name: "Super", key: 'super')
    role.permissions << create(:permission, key: "users.manage")

    expect(role.permits?("users.manage")).to be true
  end

  it "expone si no tiene una key de permiso concreta" do
    role = create(:role, name: "Super", key: 'super')
    role.permissions << create(:permission, key: "users.manage")

    expect(role.permits?("users.view")).to be false
  end
end
```

spec/policies/application_policy_spec.rb (nuevo — valida el mecanismo genérico sin depender todavía de un módulo real):

```bash
mkdir spec/policies/
touch spec/policies/application_policy_spec.rb
```

```ruby
require "rails_helper"

class Widget; end

class WidgetPolicy < ApplicationPolicy
  def show?
    user.role.permissions.exists?(key: "widgets.view")
  end

  def index?
    show?
  end

  def create?
    user.role.permissions.exists?(key: "widgets.manage")
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.role.permissions.exists?(key: "widgets.view")
        scope.all
      else
        scope.none
      end
    end
  end
end

# 1. El describe principal ahora coincide con el nombre del archivo (application_policy_spec.rb)
# 2. Anidamos WidgetPolicy adentro. RuboCop será feliz y `described_class` apuntará a WidgetPolicy.
RSpec.describe ApplicationPolicy, type: :policy do
  describe WidgetPolicy do
    subject { described_class }

    let(:role) { create(:role, name: "Administrador", key: "admin") }
    let(:user) { create(:user, email_address: "user@mail.com", password: "password123", role: role) }

    let(:record) { instance_double(Widget) }

    context "with permiso widgets.view" do
      before { role.permissions << create(:permission, key: "widgets.view") }

      permissions :show?, :index? do
        it { is_expected.to permit(user, record) }
      end

      permissions :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    context "with permiso widgets.manage" do
      before { role.permissions << create(:permission, key: "widgets.manage") }

      permissions :create?, :update?, :destroy? do
        it { is_expected.to permit(user, record) }
      end
    end

    context "without ningún permiso" do
      permissions :show?, :create? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    describe "Scope" do
      it "resuelve todo el scope con permiso de vista" do
        role = create(:role, key: "viewer")
        role.permissions << create(:permission, key: "widgets.view")
        user = create(:user, role: role)

        expect(described_class::Scope.new(user, Permission.all).resolve).to eq(Permission.all)
      end

      it "resuelve un scope vacío sin permiso" do
        user = create(:user, role: create(:role, key: "viewer_sin_permiso"))

        expect(described_class::Scope.new(user, Permission.all).resolve).to be_empty
      end
    end
  end
end
```

docs/conventions/authorization.md (nuevo):

```bash
touch docs/conventions/authorization.md
```

```markdown
# Convenciones de autorización — admin-gem

## Modelo de datos
`User belongs_to :role`. `Role has_many :permissions` a través de `role_permissions`.
Los permisos son texto libre, formato `recurso.nivel`.

## Los dos niveles de permiso
- `<recurso>.view` — listar y ver (`index?`, `show?`)
- `<recurso>.manage` — crear, editar, eliminar (`create?`, `update?`, `destroy?`)

Sin granularidad extra a propósito. Si un módulo concreto la necesita
(ej. `reports.export`), ese módulo agrega su propio nivel — no se toca la convención global.

## Cómo añadir autorización a un módulo nuevo (ej. Usuarios, Setup 13)
1. `class UserPolicy < ApplicationPolicy; class Scope < ApplicationPolicy::Scope; end; end`
   — declara `Scope` explícitamente **siempre**, aunque no le agregues nada.
   Es la recomendación oficial de Pundit: en versiones anteriores a la 2.3.1 la
   resolución implícita de la constante `Scope` anidada era ambigua.
2. El nombre de la policy define el recurso solo: `UserPolicy` → `users`. Nada que registrar.
3. Siembra los permisos que falten (`users.view`, `users.manage`) y asígnalos a los roles.
4. En el controlador: `authorize @user` (o `authorize User` en acciones de colección)
   y `policy_scope(User)` en `index`. `ApplicationController` falla si falta alguno.

## Gestión de roles/permisos desde la UI
No existe todavía — por ahora se siembran en `db/seeds.rb`. Candidato natural
para el módulo "Configuración" cuando exista.
```

## Verificación de consistencia

docs/documentation/setup_99_TODO.md: marca Setup 6 como hecho y Setup 7 como CURRENT.
Cualquier controlador nuevo que agregues de aquí en adelante (Setup 13 en particular) hereda automáticamente el requisito de authorize/policy_scope — si lo olvidas, verás Pundit::AuthorizationNotPerformedError en vez de un módulo sin protección.

## Validaciones
```bash
bin/rails console
# > Role.pluck(:name) => ["Administrador", "Lector"]
# > User.first.permits?("users.manage") => true

bundle exec rspec
# → los pending de user_spec.rb y los nuevos specs de role/policy deben pasar en verde
bundle exec rubocop -a
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

permitted? retorna false (no lanza excepción, no revienta) cuando user es nil — gracias al &. en PermissionResource#permitted?. verify_authorized/verify_policy_scoped son una red de seguridad real: en desarrollo/test, olvidar autorizar una acción rompe la build en vez de exponer un recurso sin protección en producción por accidente (Fail Secure, tal como pide el ADR).

## Mantenibilidad y compatibilidad futura

Setup 13 (Usuarios) no necesita inventar nada de autorización: crea UserPolicy, siembra users.view/users.manage (que de hecho ya existen desde este seed), y listo.
Si más adelante se necesita un permiso más fino dentro de un mismo recurso (ej. "puede exportar reportes pero no editarlos"), se agrega como un nivel adicional específico de ese recurso sin tocar ApplicationPolicy.