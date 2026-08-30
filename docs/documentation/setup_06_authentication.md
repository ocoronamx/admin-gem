# Setup: Authentication

## Objetivo

Login, logout y recuperación de contraseña usando el generador nativo de Rails 8 (decisión ya tomada en el ADR §6), con hardening real: rate limiting, contraseñas de longitud mínima, emails case-insensitive (aprovechando citext de Setup 3), y expiración de sesiones inactivas.
No hay registro público — las cuentas las crea un admin (Setup 13) o se siembra la primera por variables de entorno.

## Decisiones arquitectónicas

* Sin Rack::Attack. Verifiqué el código fuente de ActionController::RateLimiting — Rails 8.1 trae un rate_limit nativo a nivel de controlador, respaldado por el cache store configurado (Solid Cache, que ya tenemos). El propio generador de Rails ya lo usa en SessionsController. Una dependencia menos que mantener.
Doble rate limit en login: uno por IP (ya lo trae el generador) y uno adicional por email que yo agrego — el de IP no frena a alguien atacando una sola cuenta desde muchas IPs distintas.
* citext en email_address en vez del string que genera el comando por defecto — ya pagamos el costo de habilitar la extensión en Setup 3, es el momento de usarla.
* Longitud mínima de contraseña (12), sin reglas de complejidad (mayúsculas/números/símbolos obligatorios) — sigue la guía actual de NIST 800-63B: la longitud importa más que la complejidad forzada, y las reglas de complejidad tienden a producir contraseñas más débiles y predecibles en la práctica.
* Expiración de sesiones inactivas (30 días) vía un job recurrente de Solid Queue (config/recurring.yml, que ya existe desde Setup 1) — cero infraestructura nueva.
* Vistas de login/reset propias con DaisyUI, no las que trae tailwindcss-rails por defecto — las descargué también: son Tailwind puro, en inglés, con azul-600 hardcodeado, sin dark mode. Las reemplazamos por las nuestras.

## Alternativas consideradas

* Devise → descartado desde el ADR (§6); confirmado que la ruta nativa sigue siendo la correcta.
* Account lockout con contador de intentos fallidos → descartado por ahora: el rate_limit nativo (IP + email) ya cubre el caso de fuerza bruta razonablemente para un panel interno; un lockout explícito por cuenta se puede añadir después si el modelo de amenaza lo exige (queda anotado, no implementado — evitamos complejidad prematura).
* Registro público de usuarios → descartado (no-goal del ADR); el primer usuario se siembra por variable de entorno.

## Qué prevenimos

* Fuerza bruta contra el login (rate limit por IP y por cuenta).
* Cuentas duplicadas por mayúsculas en el email (mismo problema que ya resolvimos a nivel de datos en Setup 3, ahora aplicado).
* Sesiones robadas/olvidadas viviendo para siempre (poda automática a los 30 días de inactividad).
* Enumeración de cuentas vía "olvidé mi contraseña" (el mensaje de respuesta no revela si el correo existe — así lo genera Rails por defecto, lo mantenemos).
* Login/reset con el sidebar administrativo alrededor (por eso el layout application, ya preparado desde Setup 5).

## Comandos

```bash
bin/rails generate authentication
```

Esto: crea modelos/controladores/vistas, descomenta bcrypt en el Gemfile y corre bundle install, agrega include Authentication a ApplicationController, y añade las rutas de sessions/passwords.
Como tailwindcss-rails está instalado, las vistas que genera ya vienen en Tailwind (no en Rails plano) — las vamos a reemplazar de todas formas por las nuestras con tokens de DaisyUI.

## Archivos

Edita la migración generada db/migrate/..._create_users.rb antes de migrar:

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.citext :email_address, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
```

(db/migrate/..._create_sessions.rb se deja tal cual la genera el comando.)

app/models/user.rb (edita el generado):

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :password, length: { minimum: 12 }, allow_nil: true
end
```

app/models/session.rb (edita el generado):

```ruby
class Session < ApplicationRecord
  belongs_to :user

  scope :stale, -> { where(updated_at: ...30.days.ago) }
end
```

app/controllers/concerns/authentication.rb — edita únicamente find_session_by_cookie (todo lo demás queda igual a como lo genera Rails):

```ruby
    def find_session_by_cookie
      return unless cookies.signed[:session_id]

      Session.find_by(id: cookies.signed[:session_id])&.tap do |session|
        # Throttleado a 1 escritura/hora por sesión — no en cada request.
        session.touch(:updated_at) if session.updated_at < 1.hour.ago
      end
    end
```

app/controllers/sessions_controller.rb (reemplaza el generado):

```ruby
class SessionsController < ApplicationController
  layout "application"

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "Demasiados intentos. Intenta de nuevo en unos minutos." }
  rate_limit to: 10, within: 3.minutes, only: :create, name: "per_email",
             by: -> { params[:email_address].to_s.downcase },
             with: -> { redirect_to new_session_path, alert: "Demasiados intentos. Intenta de nuevo en unos minutos." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Correo o contraseña incorrectos."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
```

app/controllers/passwords_controller.rb (reemplaza el generado):

```ruby
class PasswordsController < ApplicationController
  layout "application"

  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: "Demasiados intentos. Intenta de nuevo en unos minutos." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Si el correo existe, enviamos instrucciones para restablecer la contraseña."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Contraseña actualizada. Ya puedes iniciar sesión."
    else
      redirect_to edit_password_path(params[:token]), alert: "Las contraseñas no coinciden."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "El enlace de recuperación es inválido o expiró."
    end
end
```

app/mailers/passwords_mailer.rb (edita el generado):

```ruby
class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Restablece tu contraseña", to: user.email_address
  end
end
```

app/views/passwords_mailer/reset.html.erb (reemplaza):

```erb
<p>
  Recibimos una solicitud para restablecer tu contraseña. Puedes crear una nueva desde aquí:
  <%= link_to "Restablecer contraseña", edit_password_url(@user.password_reset_token) %>.
</p>
<p>
  Este enlace expira en <%= distance_of_time_in_words(0, @user.password_reset_token_expires_in) %>.
  Si no solicitaste este cambio, puedes ignorar este correo.
</p>
```

app/views/passwords_mailer/reset.text.erb (reemplaza):

```erb
Recibimos una solicitud para restablecer tu contraseña. Puedes crear una nueva aquí:
<%= edit_password_url(@user.password_reset_token) %>

Este enlace expira en <%= distance_of_time_in_words(0, @user.password_reset_token_expires_in) %>.
Si no solicitaste este cambio, puedes ignorar este correo.
```

app/views/layouts/application.html.erb — corrige el bug del stylesheet y prepara el <body> para pantallas centradas tipo login:

```erb
<!DOCTYPE html>
<html data-theme="<%= current_theme %>">
  <head>
    <title><%= content_for(:title) || "Admin Gem" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="application-name" content="Admin Gem">
    <meta name="mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= yield :head %>

    <link rel="icon" href="/icon.png" type="image/png">
    <link rel="icon" href="/icon.svg" type="image/svg+xml">
    <link rel="apple-touch-icon" href="/icon.png">

    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-base-200">
    <main class="min-h-screen flex flex-col items-center justify-center gap-4 p-4">
      <%= render "layouts/flash" %>
      <%= yield %>
    </main>
  </body>
</html>
```

app/views/sessions/new.html.erb (reemplaza la que generó el comando):

```erb
<% content_for :title, "Iniciar sesión" %>

<div class="card w-full max-w-sm bg-base-100 shadow-xl">
  <div class="card-body">
    <h1 class="card-title justify-center text-2xl mb-4">Admin Gem</h1>

    <%= form_with url: session_path do |form| %>
      <div class="form-control mb-3">
        <label class="label" for="email_address"><span class="label-text">Correo</span></label>
        <%= form.email_field :email_address, required: true, autofocus: true,
              autocomplete: "username", class: "input input-bordered w-full" %>
      </div>

      <div class="form-control mb-2">
        <label class="label" for="password"><span class="label-text">Contraseña</span></label>
        <%= form.password_field :password, required: true, maxlength: 72,
              autocomplete: "current-password", class: "input input-bordered w-full" %>
      </div>

      <div class="text-right mb-4">
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
      <div class="form-control mb-4">
        <label class="label" for="email_address"><span class="label-text">Correo</span></label>
        <%= form.email_field :email_address, required: true, autofocus: true,
              autocomplete: "username", class: "input input-bordered w-full" %>
      </div>

      <%= form.submit "Enviar instrucciones", class: "btn btn-primary w-full" %>
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
      <div class="form-control mb-3">
        <label class="label" for="password"><span class="label-text">Nueva contraseña</span></label>
        <%= form.password_field :password, required: true, maxlength: 72,
              autocomplete: "new-password", class: "input input-bordered w-full" %>
        <span class="label-text-alt text-base-content/60 mt-1">Mínimo 12 caracteres.</span>
      </div>

      <div class="form-control mb-4">
        <label class="label" for="password_confirmation"><span class="label-text">Repite la contraseña</span></label>
        <%= form.password_field :password_confirmation, required: true, maxlength: 72,
              autocomplete: "new-password", class: "input input-bordered w-full" %>
      </div>

      <%= form.submit "Guardar", class: "btn btn-primary w-full" %>
    <% end %>
  </div>
</div>
```

app/views/layouts/_header.html.erb — reemplaza solo el bloque del dropdown de cuenta (lo demás del header queda igual):

```erb
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-circle" aria-label="Cuenta">
        <%= icon(:user_circle, css_class: "size-6") %>
      </div>
      <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box shadow z-10 w-56 mt-2 p-2">
        <li class="menu-title"><%= Current.user.email_address %></li>
        <li>
          <%# button_to genera un <form>, así que estilizamos el botón directo
              en vez de depender del selector .menu > li > a de DaisyUI %>
          <%= button_to session_path, method: :delete,
                class: "flex items-center gap-2 w-full text-left rounded-field hover:bg-base-200 px-3 py-2" do %>
            <%= icon(:arrow_right_on_rectangle, css_class: "size-4") %>
            <span>Cerrar sesión</span>
          <% end %>
        </li>
      </ul>
    </div>
```

config/recurring.yml — añade bajo production::

```yaml
production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
  prune_stale_sessions:
    command: "Session.stale.delete_all"
    schedule: every day at 3am
```

db/seeds.rb (reemplaza):

```ruby
# Sin registro público en este boilerplate: las cuentas las crea un admin
# (Setup 13) o, para el arranque inicial, se siembra aquí vía variables de entorno.
if User.none?
  email = ENV["SEED_ADMIN_EMAIL"]
  password = ENV["SEED_ADMIN_PASSWORD"]

  if email.present? && password.present?
    User.create!(email_address: email, password: password)
    puts "Usuario administrador creado: #{email}"
  else
    puts "Sin usuarios y sin SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD — no se creó ningún usuario."
  end
end
```

## Verificación de consistencia

ApplicationController ahora tiene include Authentication (lo agrega el generador automáticamente) — eso hace que todo controlador nuevo requiera login por defecto, salvo que llame a allow_unauthenticated_access como hacen SessionsController y PasswordsController.
Cuando lleguemos a Setup 13 (Usuarios), no hace falta añadir nada para protegerlo: ya viene protegido.

## Validaciones

```bash
bin/rails db:migrate
SEED_ADMIN_EMAIL=admin@admin-gem.test SEED_ADMIN_PASSWORD=cambiar-esto-123 bin/rails db:seed
bin/dev
# → visita "/" sin sesión: te redirige a /session/new (login), sin sidebar alrededor
# → entra con el usuario sembrado: te lleva de vuelta a "/" (styleguide), ahora con
#   tu correo real en el dropdown de la esquina superior derecha
# → "Cerrar sesión" te regresa al login
# → 11 intentos de login fallidos seguidos: el 11º muestra "Demasiados intentos..."
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Seguridad

authenticate_by (no find_by(email_address:).authenticate(password)) previene timing attacks al comparar contraseñas — así lo genera Rails, lo mantenemos tal cual. 
El mensaje de "olvidé mi contraseña" nunca confirma si un correo existe (previene enumeración de cuentas).
password_digest nunca se loguea ni se expone en ningún params.permit.
Las cookies de sesión son httponly + same_site: :lax (default del generador).
El rate limit doble (IP + email) cubre tanto un atacante desde una sola IP como uno distribuido contra una cuenta específica.

## Mantenibilidad y compatibilidad futura

Cuando llegue 2FA (mencionado como evolución futura en el ADR §32), se añade como un paso extra dentro de SessionsController#create sin tocar el resto — el modelo Session ya está separado del User. El lockout explícito por cuenta, si algún día hace falta, es una columna + una condición en create, no un rediseño.