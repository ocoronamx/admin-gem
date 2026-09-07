Ya revisé la rama `feat/theme` (tiene aplicado el rediseño "Ink & Bronze" que ya habíamos acordado — nada de multi-tema todavía). Construí esto encima de ella. Dos decisiones que tomé, te las dejo explícitas para que las corrijas si no es lo que querías:

1. **El selector del Super reemplaza el toggle personal**, no conviven — quité el swap del header. Fue mi respuesta a la pregunta que no llegaste a contestar: pedías guardar la selección "para todo el sistema", y un toggle personal encima de eso genera una fuente de verdad confusa (¿qué gana, la cookie del usuario o la config del Super?). Si prefieres que sí convivan, es reversible.
2. **"Otro tema" = elegir entre `light`/`dark` (que ya existen) como primer paso**, no inventé una tercera paleta nueva sin que me la pidieras — el mecanismo queda listo para que agregues un tercer tema en 5 minutos el día que lo diseñes (una entrada más en `AVAILABLE_THEMES` + un bloque `@plugin` más en `application.css`).

Para "modificar colores dentro de lo posible": los 18 tokens completos (9 pares × 2 temas) no son editables desde una UI — expondría demasiado y es fácil romper contraste. Lo que sí construí: **3 colores de marca (primario/secundario/accent)** editables con un color picker nativo (`<input type="color">`, cero dependencias), aplicados como un pequeño override sobre el tema activo. El color de texto (`-content`) de cada uno se calcula automático por luminancia — el Super no puede elegir accidentalmente un color con texto ilegible encima.

## Archivos

**Migración:**
```bash
bin/rails generate migration CreateSystemSettings
```
```ruby
class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings do |t|
      t.string :active_theme, null: false, default: "light"
      t.string :brand_primary
      t.string :brand_secondary
      t.string :brand_accent

      t.timestamps
    end
  end
end
```

**`app/models/system_setting.rb`** (nuevo):

```ruby
# Configuración global del sistema — un solo registro (singleton), no un
# recurso con índice/CRUD normal. Se accede siempre vía SystemSetting.instance.
class SystemSetting < ApplicationRecord
  include Auditable

  AVAILABLE_THEMES = %w[light dark].freeze

  validates :active_theme, inclusion: { in: AVAILABLE_THEMES }
  validate :singleton, on: :create

  def self.instance
    first_or_create!(active_theme: "light")
  end

  def brand_overrides?
    brand_primary.present? || brand_secondary.present? || brand_accent.present?
  end

  private

  def singleton
    errors.add(:base, "Solo puede existir una configuración de sistema") if SystemSetting.exists?
  end
end
```

**`app/policies/system_setting_policy.rb`** (nuevo):
```ruby
class SystemSettingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end
end
```

**`app/controllers/system_settings_controller.rb`** (nuevo):

```ruby
class SystemSettingsController < ApplicationController
  before_action :set_system_setting

  def edit
    authorize @system_setting
  end

  def update
    authorize @system_setting

    if @system_setting.update(system_setting_params)
      redirect_to edit_system_setting_path, notice: "Configuración actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_system_setting
    @system_setting = SystemSetting.instance
  end

  def system_setting_params
    params.require(:system_setting).permit(:active_theme, :brand_primary, :brand_secondary, :brand_accent)
  end
end
```

**`config/routes.rb`** — añade (singular, sin `:id`, es un singleton):

```ruby
resource :system_setting, only: %i[edit update]
```

**`app/form_builders/admin_form_builder.rb`** — añade junto a los demás `_field`:

```ruby
  def color_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end
```

**`app/views/system_settings/edit.html.erb`** (nuevo):

```erb
<% add_breadcrumb "Configuración" %>

<%= render(layout: "components/card", locals: { title: "Configuración del sistema" }) do %>
  <p class="text-sm text-base-content/60 mb-4">
    Estos ajustes aplican para todas las personas que usan el sistema, no solo para ti.
  </p>

  <%= form_with model: @system_setting, url: system_setting_path, method: :patch, builder: AdminFormBuilder do |f| %>
    <%= f.select :active_theme,
          SystemSetting::AVAILABLE_THEMES.map { |t| [t == "light" ? "Claro" : "Oscuro", t] },
          label: "Tema activo", hint: "Se aplica de inmediato a todo el sistema." %>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <%= f.color_field :brand_primary, label: "Color primario", hint: "Vacío = el color por defecto del tema." %>
      <%= f.color_field :brand_secondary, label: "Color secundario" %>
      <%= f.color_field :brand_accent, label: "Color de acento" %>
    </div>

    <%= f.submit "Guardar", class: "btn btn-primary mt-2" %>
  <% end %>
<% end %>
```

**`app/helpers/system_settings_helper.rb`** (nuevo):

```ruby
module SystemSettingsHelper
  BRAND_TOKENS = { brand_primary: "primary", brand_secondary: "secondary", brand_accent: "accent" }.freeze

  # <style> con overrides de color de marca sobre el tema activo. Vacío si
  # el Super no configuró ningún override — el tema compilado manda solo.
  def brand_override_styles
    setting = SystemSetting.instance
    return unless setting.brand_overrides?

    declarations = BRAND_TOKENS.filter_map do |attribute, token|
      value = setting.public_send(attribute)
      next if value.blank?

      "--color-#{token}: #{value}; --color-#{token}-content: #{readable_content_color_for(value)};"
    end

    tag.style(
      "[data-theme=\"#{setting.active_theme}\"] { #{declarations.join(' ')} }".html_safe,
      nonce: content_security_policy_nonce
    )
  end

  private

  # Blanco o negro según la luminancia relativa (WCAG) del color elegido —
  # no optimiza el ratio de contraste, es una guardarraíl simple para que un
  # Super no pueda dejar texto ilegible por accidente al elegir un color.
  def readable_content_color_for(hex)
    r, g, b = hex.delete("#").scan(/../).map { |c| c.to_i(16) / 255.0 }
    linear = [r, g, b].map { |c| c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    luminance = 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    luminance > 0.5 ? "#0a0a0a" : "#fafafa"
  end
end
```

**`app/views/layouts/admin.html.erb`** — añade justo después del `stylesheet_link_tag`:
```erb
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= brand_override_styles %>
```

**`app/controllers/application_controller.rb`** — reemplaza solo `set_theme` (todo lo demás del archivo queda igual):
```ruby
  # El tema ya no es una preferencia por navegador: lo decide un Super desde
  # Configuración y aplica igual para todo el sistema (ver SystemSetting).
  #
  # @return [String] "light" o "dark".
  def set_theme
    @current_theme = SystemSetting.instance.active_theme
  end
```

**`app/views/layouts/_header.html.erb`** — quita el bloque del toggle (líneas 30-36 del archivo actual):
```erb
    <label class="swap swap-rotate btn btn-ghost btn-circle" aria-label="Cambiar tema">
      ...
    </label>
```
(bórralo completo — el resto del header, incluyendo el dropdown de cuenta, queda igual).

Borra también **`app/javascript/controllers/theme_toggle_controller.js`** — ya no lo usa nadie.

**`app/views/layouts/_sidebar.html.erb`** — reemplaza la línea 23 (el placeholder deshabilitado) por el mismo patrón condicional que ya usan Roles/Usuarios/Auditoría:
```erb
  if policy(SystemSetting).edit?
    nav_items << { label: "Configuración", icon: :cog_6_tooth, path: edit_system_setting_path, available: true }
  end
```

**`config/initializers/content_security_policy.rb`** — el `<style>` del override necesita el nonce; el comentario ya decía que style-src lo tendría, pero el array se había quedado corto:
```ruby
  config.content_security_policy_nonce_directives = %w[script-src style-src]
```

**`db/seeds.rb`** — el permiso nuevo, exclusivo de Super (reemplaza las dos primeras líneas y el hash `roles`):
```ruby
permission_keys = %w[users.view users.manage roles.view roles.manage audit_logs.view]
system_permission_keys = %w[system_settings.view system_settings.manage]
permissions_by_key = (permission_keys + system_permission_keys).index_with { |key| Permission.find_or_create_by!(key: key) }

roles = {
  "super"    => { name: "Super",         permissions: permission_keys + system_permission_keys },
  "admin"    => { name: "Administrator", permissions: permission_keys },
  "standard" => { name: "Standard",      permissions: %w[users.view] },
  "client"   => { name: "Client",        permissions: [] },
  "guest"    => { name: "Guest",         permissions: [] }
}
```
(`admin` se queda exactamente con los permisos que ya tenía — no gana acceso a Configuración, solo `super`).

```bash
bin/rails db:migrate
bin/rails db:seed
bin/dev
# → entra como super@mail.com: "Configuración" aparece en el sidebar
# → cambia el tema activo y guarda: recarga con OTRO usuario (admin@mail.com,
#   por ejemplo) y confirma que también ve el tema nuevo — es del sistema, no tuyo
# → pon un color primario, guarda, confirma que botones/badges primary lo reflejan
#   y que el texto encima se ve legible
# → entra como admin@mail.com o standard@mail.com: "Configuración" NO debe
#   aparecer en el sidebar, y /system_setting/edit debe redirigir con el
#   mensaje de "no tienes permiso"
bundle exec rspec
bundle exec rubocop
```

¿Corre bien así?