# Setup 17 — CI/CD

## Objetivo

Rails ya te dejó bastante armado en Setup 2 sin que lo notáramos: `.github/workflows/ci.yml` (scan_ruby, scan_js, lint) y, más interesante, `config/ci.rb` + `bin/ci` — el nuevo runner de CI nativo de Rails 8.1 (`ActiveSupport::ContinuousIntegration`), que define los pasos una sola vez en Ruby y corre igual local o en GitHub. Le faltaban dos cosas: correr los tests, y un chequeo de "build". Las agrego ahí, no en un YAML paralelo.

## Decisiones arquitectónicas

* **`config/ci.rb` como única fuente de verdad, `.github/workflows/ci.yml` como wrapper delgado**: encontré que Rails ya generó los dos — un workflow tradicional con 3 jobs (`scan_ruby`/`scan_js`/`lint`) *y* este nuevo mecanismo (`config/ci.rb` + `bin/ci`) con básicamente los mismos pasos escritos en Ruby. Mantener las dos definiciones en paralelo significa que cada cambio futuro (agregar un gem al audit, cambiar una flag de rubocop) hay que hacerlo dos veces en dos lenguajes distintos, y tarde o temprano se desincronizan. Colapso los 3 jobs en uno solo que corre `bin/ci` — la secuencia queda definida en un solo lugar, corrible también en tu máquina.
* **Esto también resuelve literalmente "lint → security → tests → build" como secuencia, no como jobs en paralelo con `needs:`**: `CI.run do ... end` ejecuta los `step` en orden y corta en el primero que falla — es exactamente fail-fast, sin tener que orquestar dependencias entre jobs de GitHub Actions a mano.
* **Trade-off aceptado**: correr todo secuencial en un solo job es más lento en el caso feliz (todo pasa) que 3 jobs en paralelo, pero más rápido en el caso roto (no levanta Postgres ni corre RSpec si rubocop ya falló). Para un proyecto de este tamaño, priorizo lo segundo.
* **El servicio de Postgres sigue viviendo en el YAML, no en el DSL de Ruby**: `config/ci.rb` no tiene (ni debería tener) noción de "levantame un contenedor de base de datos" — eso es infraestructura del runner, no un paso de la pipeline. `bin/setup` (que el step "Setup" ya invoca) hace `db:prepare`, que crea la base si no existe — no hace falta `POSTGRES_DB` en el servicio, ni un paso de setup de DB aparte.
* **"Build" = `zeitwerk:check`, no un build de Docker todavía**: Docker es explícitamente Setup 18. Meter `assets:precompile` en modo producción acá exigiría un `RAILS_ENV`/`SECRET_KEY_BASE` distinto al resto de la pipeline (que corre en `test`) solo para este paso — la verificación real de que la imagen de producción compila bien le corresponde al Dockerfile que todavía no existe. `zeitwerk:check` sí corre en el mismo entorno que todo lo demás y detecta un error real (constantes/autoload mal nombrados) sin inventar una segunda configuración de entorno.
* **Sin `-f github` en el paso de RuboCop dentro de `config/ci.rb`**: esa flag da anotaciones lindas en el PR, pero solo tiene sentido en GitHub Actions — meterla ensuciaría la salida cuando corrés `bin/ci` en tu terminal. Se pierde esa UX puntual a cambio de que el mismo comando se comporte igual en los dos lugares.

## Alternativas consideradas

* **Mantener los 3 jobs separados y solo agregarles un 4to (`test`) con `needs:`** → descartado: hubiera dejado la lógica de seguridad/lint duplicada en YAML *y* en `config/ci.rb`, sin ninguna razón para que existan las dos.
* **Meter `docker build .` como parte del "build" de esta fase** → descartado, ver decisión de arriba — no hay Dockerfile todavía.
* **Forzar un mínimo de cobertura de SimpleCov que rompa el build** → descartado, ya quedó anotado en Setup 15: sin datos reales de dónde está parada la cobertura, sería prematuro.

## Comandos

Ninguno — todo lo que hace falta ya está instalado (`brakeman`, `bundler-audit`, `rubocop`, `simplecov`, `rspec`).

## Archivos

**config/ci.rb** (edita — agrega los pasos de Test y Build):

```ruby
# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Test: RSpec", "bundle exec rspec"

  # No es un build de Docker (eso es Setup 18, todavía no hay Dockerfile) —
  # zeitwerk:check sí corre en el mismo entorno que el resto de la pipeline
  # y detecta autoload/constantes mal nombradas antes de llegar a producción.
  step "Build: Zeitwerk check", "bin/rails zeitwerk:check"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
```

**.github/workflows/ci.yml** (reemplaza completo — un solo job que corre `bin/ci`):

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  ci:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:17
        ports: [ "5432:5432" ]
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd="pg_isready"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/admin_gem_test

    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      # bin/ci corre exactamente lo mismo que corrés local — setup, lint,
      # los tres chequeos de seguridad, RSpec, y el chequeo de Zeitwerk — en
      # ese orden, cortando en el primer paso que falle (ver config/ci.rb).
      - name: Run CI pipeline
        run: bin/ci

      - name: Upload coverage report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
          retention-days: 14
```

## Verificación de consistencia

`config/database.yml` no necesita ningún cambio — al no tener `host`/`username` hardcodeados en `test:`, `DATABASE_URL` del job pisa la config entera automáticamente (comportamiento estándar de Rails/`pg`). `dependabot.yml` queda igual — no hay ecosistema `docker` que vigilar todavía (Setup 18 lo suma cuando exista el Dockerfile).

## Validaciones

```bash
bin/ci
# → corre localmente exactamente lo mismo que va a correr en GitHub — la
#   forma más rápida de confirmar que la pipeline funciona sin esperar un push

git add . && git commit -m "..." && git push
# → mirá la pestaña Actions del repo: un solo job "ci", los pasos aparecen
#   en el log en el mismo orden que en config/ci.rb
# → forzá una falla a propósito (ej. un `binding.pry` suelto o una línea que
#   rompa rubocop) y confirmá que corta ahí, sin llegar a levantar Postgres
#   ni correr RSpec — es el comportamiento fail-fast que buscábamos
# → descargá el artifact "coverage-report" del run y abrí index.html
```

## Seguridad

`bin/bundler-audit`/`bin/importmap audit`/`bin/brakeman --exit-on-warn --exit-on-error` ahora corren en cada push/PR, no solo cuando alguien se acuerda de correrlos a mano — es la diferencia real entre "Setup 16 escribió la política" y "Setup 17 la hace imposible de saltear". `DATABASE_URL`/`POSTGRES_PASSWORD` del job son credenciales descartables del contenedor efímero de CI, no las de ningún ambiente real.

## Mantenibilidad y compatibilidad futura

Setup 18 (Docker) solo necesita sumar un `step "Build: Docker image", "docker build -t admin-gem ."` a este mismo `config/ci.rb` (y una línea a `dependabot.yml` para el ecosistema `docker`) — no un YAML nuevo, no un job nuevo, una línea en el archivo que ya existe.