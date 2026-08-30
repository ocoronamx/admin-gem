¡Excelente, gracias por el enlace! Cloné el repo para revisarlo antes de seguir (mejor verificar que asumir). Todo quedó consistente: db/schema.rb ya lista citext y pgcrypto, el Gemfile tiene los seis gemas confirmados con el comentario del CVE de resolv, y application.css + los .mjs vendored coinciden exactamente con lo que definimos (mismo tamaño de archivo que verifiqué yo mismo). También vi el ajuste que le hiciste a database.yml — la estructura primary/cache/queue/cable anidada que le faltaba a mi versión original porque dejamos activos Solid Queue/Cache/Cable desde setup_2_rails. Buen catch. Vamos con la 

# Setup: Layout administrativo

## Objetivo

Construir el "cascarón" (shell) que va a envolver todas las pantallas administrativas futuras: sidebar responsive, header con breadcrumbs y acciones globales, navegación móvil, y sidebar colapsable en desktop.
Separamos esto de application.html.erb porque setup_6_login (login) necesita una pantalla sin sidebar — un formulario de login con el menú administrativo alrededor se vería roto.

## Decisiones arquitectónicas

* Dos layouts: application.html.erb (mínimo — lo usará el login en setup_6_login) y admin.html.erb (el shell completo, default de ApplicationController).
* drawer de DaisyUI para el sidebar, con lg:drawer-open: en pantallas grandes el sidebar queda fijo y visible; en móvil se vuelve un panel off-canvas controlado por un <input type="checkbox"> — cero JavaScript propio para abrir/cerrar en móvil, es CSS puro de DaisyUI.
* Dos mecanismos de colapso distintos, a propósito: el drawer móvil es transitorio (se cierra en cada navegación, no necesita recordarse) y lo resuelve DaisyUI solo. El colapso del sidebar en desktop ("icon rail") es una preferencia que sí quieres que se recuerde entre sesiones, así que reutilizamos exactamente el patrón cookie + Stimulus que ya validaste con el tema oscuro en setup_4_design — mismo mecanismo, cero conceptos nuevos que aprender.
* Iconos: Heroicons vendored a mano, sin gema. Descargué los SVG exactos (outline, MIT) del repo oficial de Heroicons y los centralicé en un helper icon(:nombre). Evita: (a) añadir una gema para ~12 iconos estáticos, (b) SVGs pegados y duplicados por todas las vistas.
* Navegación como un array de datos, no HTML repetido por ítem — así añadir el módulo de Usuarios en setup_13 es agregar una línea, no escribir markup nuevo.
* Los módulos que no existen todavía (Usuarios, Catálogos, Configuración) se muestran deshabilitados con un badge "pronto" en vez de omitirse — así el sidebar comunica la forma final del sistema desde ya, sin generar links muertos.

## Alternativas consideradas
Gema de iconos (rails_icons, heroicon) → descartada por ahora: un helper de 15 líneas cubre exactamente lo que necesitamos sin una dependencia más que actualizar.
Sidebar colapsable con localStorage → descartado por la misma razón que el tema en setup_4_design (parpadeo en la carga inicial).

Un solo layout con content_for(:sidebar) { nil } para "ocultar" el sidebar en login → descartado: dos layouts explícitos es más simple de entender que un layout con ramas condicionales.

## Qué prevenimos
Parpadeo del estado del sidebar al recargar (mismo problema que el tema, misma solución).
Login con sidebar administrativo alrededor (Fase 5 ya queda desacoplada).
Íconos SVG pegados y ligeramente distintos entre vistas por copy-paste.
Que agregar un módulo nuevo implique tocar el HTML del sidebar en vez de una entrada de datos.

## Comandos
```bash
bin/rails generate stimulus sidebar_toggle
```

## Archivos

app/helpers/icons_helper.rb (nuevo):

```bash
bin/rails generate helper icons
```

```ruby
# Iconos Heroicons (outline, MIT) vendored a mano — sin gema.
# Fuente: https://github.com/tailwindlabs/heroicons (optimized/24/outline)
module IconsHelper
  ICONS = {
    home: '<path stroke-linecap="round" stroke-linejoin="round" d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />',
    users: '<path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />',
    squares_2x2: '<path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z" />',
    cog_6_tooth: '<path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />',
    bars_3: '<path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />',
    x_mark: '<path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />',
    sun: '<path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />',
    moon: '<path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" />',
    bell: '<path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0" />',
    user_circle: '<path stroke-linecap="round" stroke-linejoin="round" d="M17.982 18.725A7.488 7.488 0 0 0 12 15.75a7.488 7.488 0 0 0-5.982 2.975m11.963 0a9 9 0 1 0-11.963 0m11.963 0A8.966 8.966 0 0 1 12 21a8.966 8.966 0 0 1-5.982-2.275M15 9.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />',
    arrow_right_on_rectangle: '<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3 0 3-3m0 0-3-3m3 3H9" />'
  }.freeze

  def icon(name, css_class: "size-5")
    markup = ICONS.fetch(name) { raise ArgumentError, "Icono desconocido: #{name}. Añádelo a IconsHelper::ICONS." }
    content_tag(:svg, markup.html_safe,
      class: css_class, fill: "none", viewBox: "0 0 24 24",
      "stroke-width" => "1.5", stroke: "currentColor", "aria-hidden" => "true")
  end
end
```

app/helpers/breadcrumbs_helper.rb (nuevo):

```bash
bin/rails generate helper breadcrumbs
```

```ruby
# Helper para gestionar la navegación de "migas de pan" (breadcrumbs).
# Permite acumular la ruta de navegación durante el ciclo de vida del request
# (desde controladores o vistas) para luego renderizarla en el layout.
module BreadcrumbsHelper
  def add_breadcrumb(label, path = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { label: label, path: path }
  end

  def breadcrumbs
    @breadcrumbs || []
  end
end
```

app/helpers/application_helper.rb (edita el generado por Rails):

```ruby
# Helper general para la interfaz y utilidades de presentación globales.
module ApplicationHelper

  # Mapea un tipo de mensaje flash de Rails a su clase de variante correspondiente en DaisyUI.
  #
  # @param type [String, Symbol] El tipo de mensaje flash (ej. :notice, :alert, "success").
  # @return [String] La clase de alerta de DaisyUI correspondiente (ej. "alert-success").
  #   Si el tipo no coincide con ninguna clave, retorna "alert-info" por defecto.
  #
  # @example
  #   flash_alert_class(:success)  #=> "alert-success"
  #   flash_alert_class("notice")  #=> "alert-info"
  #   flash_alert_class(:unknown) #=> "alert-info"
  def flash_alert_class(type)
    {
      "notice" => "alert-info",
      "success" => "alert-success",
      "alert" => "alert-error",
      "error" => "alert-error",
      "warning" => "alert-warning"
    }.fetch(type.to_s, "alert-info")
  end
end
```

app/controllers/application_controller.rb — añade el layout por defecto y el estado del sidebar:

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  layout "admin"

  before_action :set_theme
  before_action :set_sidebar_state

  helper_method :current_theme, :sidebar_collapsed?

  private

  def set_theme
    @current_theme = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
  end

  def set_sidebar_state
    @sidebar_collapsed = cookies[:sidebar] == "collapsed"
  end

  def current_theme
    @current_theme
  end

  def sidebar_collapsed?
    @sidebar_collapsed
  end
end
```

app/javascript/controllers/sidebar_toggle_controller.js (generado por el comando de arriba, reemplaza su contenido):

```javascript
import { Controller } from "@hotwired/stimulus"

// Simétrico a theme_toggle_controller: persiste en cookie, sin round-trip al server.
export default class extends Controller {
  toggle() {
    const collapsed = document.documentElement.getAttribute("data-sidebar") === "collapsed"
    const next = collapsed ? "expanded" : "collapsed"
    document.cookie = `sidebar=${next}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-sidebar", next)
  }
}
```

app/assets/tailwind/application.css — añade al final (después de los dos bloques de tema de setup_4_design):

```css
/* Colapso de sidebar en desktop, persistido vía cookie (ApplicationController). */
[data-sidebar="collapsed"] #app-sidebar {
  width: 4.5rem;
}
[data-sidebar="collapsed"] .sidebar-label {
  display: none;
}
```

app/views/layouts/admin.html.erb (nuevo — layout por defecto):

```bash
touch app/views/layouts/admin.html.erb
```

```erb
<!DOCTYPE html>
<html data-theme="<%= current_theme %>" data-sidebar="<%= sidebar_collapsed? ? "collapsed" : "expanded" %>">
  <head>
    <title><%= content_for(:title) || "Admin Gem" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="bg-base-200">
    <div class="drawer lg:drawer-open">
      <input id="app-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col min-h-screen">
        <%= render "layouts/header" %>
        <%= render "layouts/breadcrumbs" %>

        <main class="flex-1 p-4 lg:p-6">
          <%= render "layouts/flash" %>
          <%= yield %>
        </main>
      </div>

      <div class="drawer-side z-30">
        <label for="app-drawer" aria-label="Cerrar menú" class="drawer-overlay"></label>
        <%= render "layouts/sidebar" %>
      </div>
    </div>
  </body>
</html>
```

app/views/layouts/_sidebar.html.erb (nuevo):

```bash
touch app/views/layouts/_sidebar.html.erb
```

```erb
<%
  nav_items = [
    { label: "Inicio", icon: :home, path: root_path, available: true },
    { label: "Usuarios", icon: :users, path: nil, available: false },
    { label: "Catálogos", icon: :squares_2x2, path: nil, available: false },
    { label: "Configuración", icon: :cog_6_tooth, path: nil, available: false }
  ]
%>
<aside id="app-sidebar" class="menu bg-base-100 border-r border-base-300 min-h-full w-64 p-3 flex flex-col gap-1 transition-[width] duration-200 overflow-hidden">
  <div class="flex items-center gap-2 px-2 py-3 mb-2">
    <span class="size-8 rounded-box bg-primary text-primary-content grid place-items-center font-bold shrink-0">A</span>
    <span class="sidebar-label font-semibold text-base-content whitespace-nowrap">Admin Gem</span>
  </div>

  <ul class="menu-vertical w-full">
    <% nav_items.each do |item| %>
      <li>
        <% if item[:available] %>
          <%= link_to item[:path], class: (current_page?(item[:path]) ? "menu-active" : nil) do %>
            <%= icon(item[:icon]) %>
            <span class="sidebar-label whitespace-nowrap"><%= item[:label] %></span>
          <% end %>
        <% else %>
          <span class="text-base-content/40 cursor-not-allowed" aria-disabled="true" title="Próximamente">
            <%= icon(item[:icon]) %>
            <span class="sidebar-label whitespace-nowrap"><%= item[:label] %></span>
            <span class="sidebar-label badge badge-ghost badge-sm ml-auto">pronto</span>
          </span>
        <% end %>
      </li>
    <% end %>
  </ul>
</aside>
```

app/views/layouts/_header.html.erb (nuevo):

```bash
touch app/views/layouts/_header.html.erb
```

```erb
<header class="navbar bg-base-100 border-b border-base-300 px-4 lg:px-6 gap-2">
  <div class="flex-1 flex items-center gap-2">
    <label for="app-drawer" class="btn btn-ghost btn-circle lg:hidden" aria-label="Abrir menú">
      <%= icon(:bars_3) %>
    </label>
    <button type="button" class="btn btn-ghost btn-circle hidden lg:inline-flex"
            data-controller="sidebar-toggle" data-action="sidebar-toggle#toggle"
            aria-label="Colapsar barra lateral">
      <%= icon(:bars_3) %>
    </button>
  </div>

  <div class="flex items-center gap-1">
    <button type="button" class="btn btn-ghost btn-circle" aria-label="Notificaciones" disabled>
      <%= icon(:bell) %>
    </button>

    <label class="swap swap-rotate btn btn-ghost btn-circle" aria-label="Cambiar tema">
      <input type="checkbox" value="dark" class="theme-controller"
             data-controller="theme-toggle" data-action="change->theme-toggle#persist"
             <%= "checked" if current_theme == "dark" %> />
      <span class="swap-on"><%= icon(:moon) %></span>
      <span class="swap-off"><%= icon(:sun) %></span>
    </label>

    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-circle" aria-label="Cuenta">
        <%= icon(:user_circle, css_class: "size-6") %>
      </div>
      <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box shadow z-10 w-52 mt-2 p-2">
        <li class="menu-title">Sin sesión (Fase 5)</li>
        <li>
          <span class="text-base-content/40 cursor-not-allowed">
            <%= icon(:arrow_right_on_rectangle) %> Cerrar sesión
          </span>
        </li>
      </ul>
    </div>
  </div>
</header>
```

app/views/layouts/_breadcrumbs.html.erb (nuevo):

```bash
touch app/views/layouts/_breadcrumbs.html.erb
```

```erb
<% if breadcrumbs.any? %>
  <div class="breadcrumbs text-sm px-4 lg:px-6 pt-4 text-base-content/70">
    <ul>
      <li><%= link_to "Inicio", root_path %></li>
      <% breadcrumbs.each do |crumb| %>
        <li><%= crumb[:path] ? link_to(crumb[:label], crumb[:path]) : crumb[:label] %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

app/views/layouts/_flash.html.erb (nuevo):

```bash
touch app/views/layouts/_flash.html.erb
```

```erb
<% flash.each do |type, message| %>
  <div class="alert <%= flash_alert_class(type) %> shadow-sm mb-4" role="alert">
    <span><%= message %></span>
  </div>
<% end %>
```

app/views/pages/styleguide.html.erb — quita el toggle de tema (ya vive en el header global) y añade breadcrumb + los iconos vendored como referencia:

```erb
<% add_breadcrumb "Design System" %>

<div class="space-y-8">
  <h1 class="text-2xl font-semibold text-base-content">Design System — admin-gem</h1>

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

  <section class="card bg-base-100 shadow p-6 space-y-3">
    <h2 class="font-medium">Iconos disponibles (IconsHelper)</h2>
    <div class="flex flex-wrap gap-4">
      <% IconsHelper::ICONS.each_key do |name| %>
        <div class="flex flex-col items-center gap-1 text-xs text-base-content/60">
          <%= icon(name) %>
          <span><%= name %></span>
        </div>
      <% end %>
    </div>
  </section>
</div>
```

## Verificación de consistencia

app/views/layouts/application.html.erb no lleva layout "admin" — sigue siendo el layout mínimo por defecto de Rails, listo para que setup_6_login lo use en el login con layout "application" explícito en SessionsController.

## Validaciones

```bash
bin/dev
# → /styleguide: sidebar visible en desktop, breadcrumb "Inicio / Design System"
# → reduce la ventana (<1024px): el sidebar desaparece, aparece el botón hamburguesa
# → clic en el botón de colapsar (desktop): el sidebar se reduce a solo íconos,
#   recarga la página → se mantiene colapsado (cookie)
# → el toggle de tema en el header sigue funcionando igual que en setup_4_design
bundle exec rubocop
```

## Seguridad

Las cookies theme y sidebar solo aceptan valores de una lista blanca antes de usarse (set_theme, set_sidebar_state) — nunca se refleja un valor arbitrario del usuario en atributos HTML. El menú de cuenta y "Cerrar sesión" están deshabilitados a propósito hasta que exista autenticación real en setup_6_login — no hay ningún link que aparente funcionar sin hacerlo.

# Mantenibilidad y compatibilidad futura

Añadir un módulo nuevo al sidebar en setup_13 es agregar un hash a nav_items con available: true — nada de HTML nuevo. IconsHelper::ICONS es el único lugar donde vive el inventario de íconos del sistema, así que setup_8 (componentes) puede apoyarse en él sin reinventarlo.