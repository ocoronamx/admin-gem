# Pasos de configuración de sistema

1. **Fundación visual** — los dos temas base (`classic` e `ink_bronze`) coexistiendo en CSS, cero cambio visible todavía.
2. **Capa de datos** — `SystemSetting`, Active Storage, policy, permisos, seeds. Existe pero nada lo usa todavía.
3. **El cambio real** — controlador, rutas, vista de configuración, y ahí sí se apaga la cookie personal y se prende el sistema nuevo.
4. **Specs + limpieza** — tests del modelo/policy/controller, y borrar lo que quedó muerto (`theme_toggle_controller.js`, la cookie).


## Paso 1 — Dos temas base, sin romper nada

**Decisión**: renombro lo que ya existe en `main` (`"light"`/`"dark"`) a `classic-light`/`classic-dark` — es exactamente la misma paleta, solo con nombre nuevo — y agrego `ink_bronze-light`/`ink_bronze-dark` (la paleta de `feat/theme`) **dormida**: existe en la CSS pero nada la selecciona todavía. Cero cambio visible al terminar este paso; se verifica a mano en devtools.

**app/assets/tailwind/application.css** — reemplaza los dos bloques `@plugin` actuales por estos cuatro (el bloque `@theme` de arriba, con `--radius-*`/`--border`/etc., queda exactamente igual):

```css
@plugin "./daisyui-theme.mjs" {
  name: "classic-light";
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
}

@plugin "./daisyui-theme.mjs" {
  name: "classic-dark";
  default: false;
  prefersdark: false;
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
}

/* Dormido por ahora — nada lo selecciona hasta el Paso 3. Paleta cálida
   ("Ink & Bronze"): bronce/latón primario, slate frío secundario, teal
   profundo de acento. Verificado contra WCAG 2.1 (AA, ≥4.3:1). */
@plugin "./daisyui-theme.mjs" {
  name: "ink_bronze-light";
  default: false;
  prefersdark: false;
  color-scheme: light;

  --color-base-100: oklch(99% 0.004 75);
  --color-base-200: oklch(96% 0.006 75);
  --color-base-300: oklch(91% 0.008 75);
  --color-base-content: oklch(22% 0.015 60);

  --color-primary: oklch(48% 0.13 60);
  --color-primary-content: oklch(98% 0.01 60);
  --color-secondary: oklch(42% 0.03 250);
  --color-secondary-content: oklch(97% 0.005 250);
  --color-accent: oklch(48% 0.09 190);
  --color-accent-content: oklch(97% 0.01 190);
  --color-neutral: oklch(28% 0.02 60);
  --color-neutral-content: oklch(96% 0.005 60);

  --color-info: oklch(45% 0.12 230);
  --color-info-content: oklch(97% 0.01 230);
  --color-success: oklch(50% 0.1 155);
  --color-success-content: oklch(97% 0.02 155);
  --color-warning: oklch(72% 0.14 75);
  --color-warning-content: oklch(22% 0.04 75);
  --color-error: oklch(53% 0.19 25);
  --color-error-content: oklch(97% 0.02 25);
}

@plugin "./daisyui-theme.mjs" {
  name: "ink_bronze-dark";
  default: false;
  prefersdark: false;
  color-scheme: dark;

  --color-base-100: oklch(18% 0.012 60);
  --color-base-200: oklch(22% 0.014 60);
  --color-base-300: oklch(27% 0.016 60);
  --color-base-content: oklch(92% 0.008 70);

  --color-primary: oklch(72% 0.13 65);
  --color-primary-content: oklch(18% 0.03 60);
  --color-secondary: oklch(72% 0.02 250);
  --color-secondary-content: oklch(18% 0.02 250);
  --color-accent: oklch(72% 0.1 190);
  --color-accent-content: oklch(18% 0.03 190);
  --color-neutral: oklch(85% 0.01 60);
  --color-neutral-content: oklch(20% 0.02 60);

  --color-info: oklch(72% 0.11 230);
  --color-info-content: oklch(18% 0.03 230);
  --color-success: oklch(70% 0.12 155);
  --color-success-content: oklch(18% 0.03 155);
  --color-warning: oklch(78% 0.13 75);
  --color-warning-content: oklch(22% 0.04 75);
  --color-error: oklch(68% 0.18 25);
  --color-error-content: oklch(18% 0.03 25);
}
```

Nota: le quité `prefersdark: true` al que lo tenía en `feat/theme` — con **dos** temas de fondo oscuro coexistiendo (`classic-dark`, y ahora `ink_bronze-dark` dormido), dejar `prefersdark` en cualquiera de los dos sería arbitrario hasta que el Paso 3 decida esto de verdad vía `SystemSetting`. Por ahora todo lo maneja `classic-*` explícito, no la preferencia del sistema operativo.

**app/controllers/application_controller.rb** — cambia solo `set_theme` (transición: sigue leyendo la cookie personal, pero ahora compone el nombre completo del tema; esto lo reemplaza el Paso 3):

```ruby
  # TRANSICIÓN (Paso 1 de 4 hacia SystemSetting): sigue leyendo la cookie
  # personal, pero ahora compone el nombre completo del tema ("classic-light",
  # etc.) — hardcodeado a "classic" hasta que el Paso 3 lo reemplace por la
  # selección real del sistema.
  #
  # @return [String] El tema activo compuesto, ej. "classic-dark".
  def set_theme
    mode = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
    @current_theme = "classic-#{mode}"
  end
```

**app/javascript/controllers/theme_toggle_controller.js** — mismo criterio, un solo `data-theme` compuesto:

```javascript
import { Controller } from "@hotwired/stimulus"

// TRANSICIÓN (Paso 1 de 4): sigue siendo la cookie personal, "classic-"
// hardcodeado hasta el Paso 3.
export default class extends Controller {
  persist(event) {
    const theme = event.target.checked ? "dark" : "light"
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-theme", `classic-${theme}`)

    window.dispatchEvent(new CustomEvent("theme:change"))
  }
}
```

## FIX

Nonces no cubren `style=""` aplicado dinámicamente (ApexCharts, y ahora confirmamos que Turbo también), y mezclar nonce + `unsafe-inline` en el mismo directive hace que el navegador ignore el `unsafe-inline` — por eso hay que sacar `style-src` de `nonce_directives`, no solo agregar la palabra clave.

**config/initializers/content_security_policy.rb** (reemplaza completo — esta vez asegurate de guardar el archivo):

```ruby
# Be sure to restart your server when you modify this file.

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
    # unsafe-inline acá, no en script-src: ApexCharts y Turbo fijan estilos
    # vía elemento.style / <style> dinámico en tiempo real — un nonce NUNCA
    # puede cubrir eso (solo cubre <style> estático con el atributo nonce=
    # puesto a mano). No ejecuta JS, así que el riesgo real de XSS (que sigue
    # cubierto por script-src estricto) no se ve afectado.
    policy.style_src       :self, :unsafe_inline
    policy.connect_src     :self
    policy.base_uri        :none
    policy.frame_ancestors :none
  end

  # El importmap de Rails inyecta <script type="importmap"> y el bootstrap
  # de módulos como scripts inline — sin nonce, script-src :self los
  # bloquearía y se cae toda la app.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }

  # Solo scripts usan nonce. style-src usa unsafe-inline (ver arriba) —
  # mezclar nonce + unsafe-inline en el mismo directive hace que el navegador
  # IGNORE unsafe-inline (así lo define el spec), así que style-src no va acá.
  config.content_security_policy_nonce_directives = %w[script-src]
end
```

## Validación

```bash
bin/dev
# → /dashboard o /styleguide, con los charts visibles
# → clickeá el switch de tema un par de veces — antes esto disparaba el
#   error de "onThemeChange" que se ve al final de tu log
# → consola de Chrome: cero errores de "Applying inline style violates..."
#   (ni de Turbo, ni de ApexCharts)

git add config/initializers/content_security_policy.rb
git commit -m "Se corrige CSP: unsafe-inline en style-src para ApexCharts/Turbo"
git push
```

Confirmame con la consola limpia esta vez, y seguimos con el Paso 2 de `SystemSetting`.

## Validaciones

```bash
bin/dev
# → todo se ve exactamente igual que antes — el toggle del header sigue
#   alternando claro/oscuro sin ningún cambio visible

# En devtools console, para confirmar que ink_bronze está bien formado
# aunque todavía nadie lo seleccione:
document.documentElement.setAttribute("data-theme", "ink_bronze-light")
# → /styleguide debería verse con la paleta cálida (bronce/latón). Volvé a
#   "classic-light" (o recargá) para dejarlo como estaba.

bundle exec rubocop
```

Confirmame que esto corre bien y sin diferencias visuales, y seguimos con el Paso 2 (el modelo `SystemSetting`, Active Storage, policy y seeds — todavía sin conectar a nada que se vea).

---

## Paso 2 — Capa de datos: `SystemSetting`

Todavía nada de esto se ve ni se usa — es el modelo, la migración, la policy y los permisos, verificables por consola/specs antes de conectar nada al render en el Paso 3.

**Comandos:**

```bash
bin/rails active_storage:install
bin/rails generate migration CreateSystemSettings
```

**db/migrate/…_create_system_settings.rb** (edita la generada):

```ruby
class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings do |t|
      t.string :app_name, null: false, default: "Admin Gem"
      t.string :support_email

      t.string :base_theme, null: false, default: "ink_bronze"
      t.string :color_mode, null: false, default: "light"

      # OKLCH — snapshot de los valores reales del tema base activo. Se
      # resincroniza sola al cambiar de base_theme (ver SystemSetting#sync_default_colors).
      t.jsonb :default_colors_light, null: false, default: {}
      t.jsonb :default_colors_dark,  null: false, default: {}

      # Hex — overrides de marca, independientes del tema base (un color
      # custom se mantiene igual sin importar qué paleta de fondo esté activa).
      t.jsonb :custom_colors_light, null: false, default: {}
      t.jsonb :custom_colors_dark,  null: false, default: {}

      # Respaldo de un nivel para "restaurar anteriores" — no reemplaza a
      # Auditable (ya incluido abajo), que guarda el historial completo.
      t.jsonb :previous_colors_light, null: false, default: {}
      t.jsonb :previous_colors_dark,  null: false, default: {}

      t.timestamps
    end
  end
end
```

**app/models/system_setting.rb** (nuevo):

```ruby
# Configuración global del sistema — un solo registro (singleton), no un
# recurso con índice/CRUD normal. Se accede siempre vía SystemSetting.instance.
class SystemSetting < ApplicationRecord
  include Auditable

  has_one_attached :logo
  has_one_attached :favicon

  BASE_THEMES = %w[classic ink_bronze].freeze
  COLOR_MODES = %w[light dark].freeze

  # Valores reales de cada tema base, en OKLCH — tienen que coincidir a mano
  # con application.css (Paso 1). No hay forma de leer las custom properties
  # ya compiladas desde Ruby en boot time, así que esto se mantiene
  # sincronizado manualmente si se edita la paleta.
  BASE_THEME_DEFAULTS = {
    "classic" => {
      "light" => { "primary" => "oklch(45% 0.15 264)", "secondary" => "oklch(55% 0.04 255)", "accent" => "oklch(70% 0.14 200)" },
      "dark"  => { "primary" => "oklch(70% 0.14 264)", "secondary" => "oklch(70% 0.03 255)", "accent" => "oklch(75% 0.13 200)" }
    },
    "ink_bronze" => {
      "light" => { "primary" => "oklch(48% 0.13 60)", "secondary" => "oklch(42% 0.03 250)", "accent" => "oklch(48% 0.09 190)" },
      "dark"  => { "primary" => "oklch(72% 0.13 65)", "secondary" => "oklch(72% 0.02 250)", "accent" => "oklch(72% 0.1 190)" }
    }
  }.freeze

  validates :app_name, presence: true
  validates :base_theme, inclusion: { in: BASE_THEMES }
  validates :color_mode, inclusion: { in: COLOR_MODES }
  validates :logo, content_type: %w[image/png image/jpeg image/svg+xml image/webp], size: { less_than: 2.megabytes }
  validates :favicon, content_type: %w[image/png image/x-icon image/vnd.microsoft.icon], size: { less_than: 512.kilobytes }
  validate :singleton, on: :create

  before_validation :sync_default_colors, if: :base_theme_changed?

  def self.instance
    first_or_create!(app_name: "Admin Gem")
  end

  # "classic-light", "ink_bronze-dark"... — el data-theme real a renderizar
  # (todavía sin conectar a nada — eso es el Paso 3).
  def theme_name
    "#{base_theme}-#{color_mode}"
  end

  # Custom si existe; si no, el default del tema. Para pintar swatches de
  # referencia — no para precargar el color picker (ver nota del Paso 3
  # sobre por qué OKLCH no sirve como value de un <input type="color">).
  def colors_for(mode)
    public_send("custom_colors_#{mode}").presence || public_send("default_colors_#{mode}")
  end

  def custom_colors?(mode)
    public_send("custom_colors_#{mode}").present?
  end

  # No persiste sola — el controller (Paso 3) la combina con el resto de
  # los atributos y guarda todo junto en un solo `save`.
  def assign_custom_colors(mode, colors)
    assign_attributes(
      "previous_colors_#{mode}" => public_send("custom_colors_#{mode}"),
      "custom_colors_#{mode}" => colors.compact_blank
    )
  end

  def restore_previous_colors!(mode)
    update!("custom_colors_#{mode}" => public_send("previous_colors_#{mode}"))
  end

  def reset_colors_to_theme_default!(mode)
    assign_custom_colors(mode, {})
    save!
  end

  private

  def sync_default_colors
    COLOR_MODES.each { |mode| assign_attributes("default_colors_#{mode}" => BASE_THEME_DEFAULTS.fetch(base_theme).fetch(mode)) }
  end

  def singleton
    errors.add(:base, "Solo puede existir una configuración de sistema") if SystemSetting.exists?
  end
end
```

**app/policies/system_setting_policy.rb** (nuevo — vacío, mismo patrón que `RolePolicy`/`UserPolicy`; el nombre de la clase deriva el recurso `system_settings` sin registrar nada aparte):

```ruby
class SystemSettingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end
end
```

**db/seeds.rb** — reemplaza el bloque de permisos/roles (exclusividad de `system_settings` para `super` lograda con datos, no con un `if role.key == "super"` hardcodeado en ningún lado):

```ruby
# Cada módulo nuevo declara sus propios permisos "<recurso>.view" / "<recurso>.manage"
# (ver docs/conventions/authorization.md).
permission_keys = %w[users.view users.manage roles.view roles.manage audit_logs.view]

# system_settings queda exclusivo de "super" — ni siquiera "admin" lo tiene.
# La exclusividad vive acá, en los datos sembrados, no en un chequeo de rol
# hardcodeado en la policy (mismo criterio que el resto del RBAC).
super_only_permission_keys = %w[system_settings.view system_settings.manage]

permissions_by_key = (permission_keys + super_only_permission_keys).index_with { |key| Permission.find_or_create_by!(key: key) }

roles = {
  "super"    => { name: "Super",         permissions: permission_keys + super_only_permission_keys },
  "admin"    => { name: "Administrator", permissions: permission_keys },
  "standard" => { name: "Standard",      permissions: %w[users.view] },
  "client"   => { name: "Client",        permissions: [] },
  "guest"    => { name: "Guest",         permissions: [] }
}
```

(el resto de `seeds.rb` —el loop de `roles.each`, la creación de usuarios— queda exactamente igual)

## Validaciones

```bash
bin/rails db:migrate
bin/rails db:seed

bin/rails console
# > s = SystemSetting.instance
# > s.theme_name                    # => "ink_bronze-light"
# > s.default_colors_light          # => {"primary"=>"oklch(48% 0.13 60)", ...} (se sincronizó solo al crearse)
# > s.base_theme = "classic"; s.save!
# > s.default_colors_light          # => ahora los OKLCH de "classic"
# > s.custom_colors?("light")       # => false
# > s.assign_custom_colors("light", { "primary" => "#3b2a1a" }); s.save!
# > s.colors_for("light")           # => {"primary"=>"#3b2a1a"}
# > s.restore_previous_colors!("light")
# > s.colors_for("light")           # => {} otra vez (no había nada antes del primer cambio)
# > User.find_by(email_address: "admin@mail.com").permits?("system_settings.view")  # => false
# > User.find_by(email_address: "super@mail.com").permits?("system_settings.view")  # => true
# > AuditLog.last.resource          # => el SystemSetting — Auditable ya está registrando esto

bundle exec rubocop
```

Confirmame que corre bien y seguimos con el Paso 3 — ahí sí se conecta todo: controlador, rutas, la vista de configuración, y el corte real de la cookie personal por el sistema nuevo (incluyendo el favicon).

