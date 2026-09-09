# Setup 18 — Docker / Deployment

## Objetivo

Rails 8 ya generó un `Dockerfile` de producción sólido (multi-stage, usuario no-root, jemalloc, bootsnap, Thruster) y todo el andamiaje de Kamal 2 (`config/deploy.yml`, `.kamal/secrets`) desde Setup 2 — no hay que escribir esto desde cero. El trabajo real acá es: conectar `assume_ssl` (Setup 16) con el proxy de Kamal, decidir la historia de base de datos en producción (coherente con lo que ya fijaste en Setup 3), y cerrar las dos promesas que dejé pendientes en Setup 17.

## Decisiones arquitectónicas

* **`config.assume_ssl = true`, ahora sí**: el propio comentario del `deploy.yml` generado ya lo advertía ("Using an SSL proxy like this requires turning on config.assume_ssl and config.force_ssl") pero hasta ahora no aplicaba porque no habíamos activado el proxy de Kamal. El proxy termina TLS y reenvía HTTP plano al contenedor — sin `assume_ssl`, `force_ssl` (Setup 16) vería cada request como inseguro desde adentro del contenedor y podría generar un loop de redirect.
* **DB externa gestionada como default, no un accessory de Postgres self-hosted**: tu propio razonamiento en Setup 3 para fijar PG 17 fue explícitamente "compatibilidad garantizada en RDS, Cloud SQL, Supabase, Render, Fly.io" — eso ya anticipaba un proveedor gestionado, no una base corriendo en el mismo Docker network que la app. `database.yml` ya vino preparado para esto (`DATABASE_HOST`/`ADMIN_GEM_DATABASE_PASSWORD` vía ENV) desde que Rails lo generó — solo faltaba conectarlo en `deploy.yml`. Dejo un accessory de Postgres comentado como alternativa, no como default.
* **Registry: `ghcr.io`, no el placeholder `localhost:5555`**: gratis, sin cuenta nueva que crear, y se autentica con el mismo `GITHUB_TOKEN` que ya usás en Setup 17 — encaja mejor con "sin lock-in de PaaS" que Docker Hub (que sigue siendo de un tercero) o que dejar un placeholder que nadie va a recordar cambiar.
* **`docker-compose.yml` para Postgres local, opcional**: tu ADR ya lo anotó como "opcional" en §10 — Ruby sigue corriendo nativo (`bin/dev`), esto es solo para no obligar a nadie que clone el repo a instalar PostgreSQL en su máquina si prefiere un contenedor.
* **Cierro las dos promesas de Setup 17**: el step de build de Docker en `config/ci.rb`, y el ecosistema `docker` en `dependabot.yml` — ambos quedaron explícitamente anotados como "para cuando exista el Dockerfile", y ya existe.
* **Sin push automático a un registro ni deploy automático desde CI**: pushear una imagen y ejecutar `kamal deploy` asume un servidor real con IP/dominio conocido — no algo que un boilerplate pueda decidir por vos. El `step` de Docker en CI es un build-only smoke test (¿compila la imagen?), no CD real. Eso lo conecta quien lo despliegue de verdad, cuando tenga servidor.

## Alternativas consideradas

* **Accessory de Postgres en el mismo servidor** → no descartado del todo, dejado comentado como alternativa válida para quien prefiera self-hosted — pero no es el default, por la razón de arriba.
* **`proxy: ssl: true` con un dominio de ejemplo activado** → descartado: un dominio inventado (`app.example.com`) que alguien copie sin cambiar rompe el deploy real de forma confusa. Mejor un placeholder explícito que obligue a pensarlo.
* **Pushear la imagen a `ghcr.io` como parte de `config/ci.rb`** → descartado por ahora: agregaría la necesidad de un `GITHUB_TOKEN` con permisos de packages en el workflow — es una línea de más cuando exista un deploy real, no antes.

## Comandos

Ninguno — Dockerfile, Kamal y sus binstubs (`bin/kamal`, `bin/thrust`) ya estaban instalados desde Setup 2.

## Archivos

**config/environments/production.rb** — descomenta:

```ruby
  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Kamal's built-in proxy termina TLS y reenvía HTTP plano al contenedor — sin esto,
  # force_ssl (Setup 16) vería cada request como inseguro desde adentro.
  config.assume_ssl = true
  config.force_ssl = true
```

**config/deploy.yml** (edita las secciones relevantes, el resto del template queda igual):

```yaml
# Deploy to these servers.
servers:
  web:
    - <TU_IP_O_DOMINIO>  # reemplazá esto antes de deployar — no hay forma de que el boilerplate lo adivine

# Enable SSL auto certification via Let's Encrypto, y assume_ssl/force_ssl en production.rb
# (ver config/environments/production.rb — ya activados en esta fase).
proxy:
  ssl: true
  host: <TU_DOMINIO>  # ej. admin.tuapp.com — reemplazá antes de deployar

# Where you keep your container images.
registry:
  server: ghcr.io
  username: <TU_USUARIO_DE_GITHUB>

  password:
    - KAMAL_REGISTRY_PASSWORD

# Inject ENV variables into containers (secrets come from .kamal/secrets).
env:
  secret:
    - RAILS_MASTER_KEY
    - ADMIN_GEM_DATABASE_PASSWORD
  clear:
    SOLID_QUEUE_IN_PUMA: true

    # Base de datos externa gestionada (RDS/Cloud SQL/Supabase/Render/Fly.io) —
    # ver docs/conventions/database.md y el ADR §3.2 sobre por qué PG 17 se
    # eligió pensando en proveedores gestionados. Si preferís self-hosted,
    # ver el accessory comentado más abajo en vez de esto.
    DATABASE_HOST: <TU_HOST_DE_POSTGRES>

# ... (aliases, volumes, asset_path, builder quedan igual que el default)

# Alternativa: Postgres self-hosted como accessory en vez de un proveedor
# gestionado (ver "Decisiones" — no es el default, pero es una opción válida
# si preferís no depender de un tercero).
# accessories:
#   db:
#     image: postgres:17
#     host: <TU_IP_O_DOMINIO>
#     port: "127.0.0.1:5432:5432"
#     env:
#       clear:
#         POSTGRES_USER: admin_gem
#         POSTGRES_DB: admin_gem_production
#       secret:
#         - POSTGRES_PASSWORD
#     directories:
#       - data:/var/lib/postgresql/data
```

**.kamal/secrets** — agrega la contraseña de la DB:

```bash
# Grab the registry password from ENV — ghcr.io usa un Personal Access Token
# con permiso "write:packages" como password.
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD

# Contraseña de la base de datos externa (ver DATABASE_HOST en deploy.yml).
ADMIN_GEM_DATABASE_PASSWORD=$ADMIN_GEM_DATABASE_PASSWORD

# Improve security by using a password manager. Never check config/master.key into git!
RAILS_MASTER_KEY=$(cat config/master.key)
```

**config/ci.rb** — cierra la promesa de Setup 17, agrega al final (antes del bloque comentado de signoff):

```ruby
  step "Test: RSpec", "bundle exec rspec"
  step "Build: Zeitwerk check", "bin/rails zeitwerk:check"

  # Build-only: confirma que la imagen compila, no la pushea ni deploya.
  # Eso lo conecta quien tenga un servidor real (ver config/deploy.yml).
  step "Build: Docker image", "docker build -t admin_gem ."
```

**.github/dependabot.yml** — cierra la otra promesa de Setup 17:

```yaml
version: 2
updates:
- package-ecosystem: bundler
  directory: "/"
  schedule:
    interval: weekly
  open-pull-requests-limit: 10
- package-ecosystem: docker
  directory: "/"
  schedule:
    interval: weekly
  open-pull-requests-limit: 10
- package-ecosystem: github-actions
  directory: "/"
  schedule:
    interval: weekly
  open-pull-requests-limit: 10
```

**docker-compose.yml** (nuevo, opcional — para Postgres local sin instalarlo en la máquina):

```yaml
# Opcional (ver ADR §10) — Ruby sigue corriendo nativo (`bin/dev`). Esto es
# solo para levantar Postgres en un contenedor si preferís no instalarlo:
#   docker compose up -d
#   bin/setup
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Verificación de consistencia

`database.yml` no cambia — ya venía preparado para `DATABASE_HOST`/`ADMIN_GEM_DATABASE_PASSWORD` desde que Rails lo generó en Setup 2, `deploy.yml` solo lo conecta. El Dockerfile no cambia — ya estaba bien armado para este stack (Tailwind CLI standalone, sin Node, precompila solo).

## Validaciones

```bash
bin/ci
# → el nuevo step "Build: Docker image" corre al final — confirmá que
#   docker build efectivamente termina sin error antes de seguir

docker run --rm -e SECRET_KEY_BASE_DUMMY=1 admin_gem bin/rails runner "puts 'ok'"
# → smoke test rápido: la imagen arranca y puede correr Ruby, sin necesitar
#   una base de datos real todavía

# Con un servidor real y los placeholders de deploy.yml ya reemplazados:
bin/kamal setup   # primera vez
bin/kamal deploy  # deploys siguientes
```

## Seguridad

`ADMIN_GEM_DATABASE_PASSWORD`/`RAILS_MASTER_KEY`/`KAMAL_REGISTRY_PASSWORD` nunca están en `deploy.yml` ni en `.kamal/secrets` en texto plano — ese archivo solo referencia variables de entorno de la máquina que ejecuta `kamal deploy`, nunca credenciales reales versionadas. `assume_ssl` + `force_ssl` juntos son necesarios y no redundantes: uno le dice a Rails "confiá en que la conexión ya es HTTPS" (porque el proxy la terminó), el otro sigue rechazando cualquier intento de bypassear eso.

## Mantenibilidad y compatibilidad futura

Setup 19 (Documentation) es quien realmente le explica a un tercero cómo deployar esto — acá dejé los placeholders y comentarios suficientes para que esa fase solo tenga que documentar el "por qué", no inventar la config desde cero. Si el proyecto crece a necesitar múltiples servidores web, `servers.web` ya acepta una lista — no hay rediseño ahí.