# Setup 19 — Documentation

Setup 20 queda tal cual te lo di — sigue siendo válido como foto del estado del proyecto en ese momento; nada de lo que agrego acá lo contradice, solo lo completa. Ahora sí, el 19.

## Decisiones

* **`docs/adr/` como registros cortos y independientes, no un resumen de `setup_001_architecture.md`**: ese documento y cada `setup_NN_*.md` ya tienen la narrativa completa (contexto, alternativas, razonamiento). Un ADR de verdad es lo opuesto — una o dos pantallas, escaneable, que alguien lea en 30 segundos para entender *qué* se decidió y *por qué*, con un link al documento largo si quiere el detalle completo. Elegí las ~14 decisiones que alguien nuevo en el proyecto más probablemente cuestionaría o querría revisar ("¿por qué no Devise/Ransack/Redis?"), no cada micro-decisión de cada fase.
* **CHANGELOG con una sola sección "Unreleased"**: no hay tags ni versiones semánticas todavía — inventar `v0.1.0` sería ficción. El formato Keep a Changelog empieza a tener sentido real recién cuando exista el primer release; por ahora documento qué hay, agrupado por categoría, listo para convertirse en `v0.1.0` el día que taggees algo.
* **README no asume que ya está deployado**: la sección de deploy apunta a lo que dejaste listo en Setup 18 (`config/deploy.yml`, comentado con placeholders) sin fingir que hay un servidor real corriendo.
* **SECURITY.md declara qué SÍ está cubierto (CSP, headers, Brakeman en CI) en vez de una plantilla genérica** — un SECURITY.md que no dice nada específico del proyecto es ruido.

## Archivos

**README.md** (reemplaza el placeholder default de Rails):

```markdown
# Admin Gem

Boilerplate administrativo en Rails 8.1 — RBAC completo (roles/permisos),
auditoría, formularios y tablas reutilizables, sin las dependencias que
sueles terminar quitando de un boilerplate genérico (sin Devise, sin
Ransack, sin Redis, sin Node.js).

## Stack

- **Ruby 3.4.10 / Rails 8.1** — ver `docs/adr/0001-sin-nodejs.md` y `docs/documentation/setup_001_architecture.md` para el razonamiento completo detrás de cada elección de versión.
- **PostgreSQL 17** (`citext`, `pgcrypto`, `jsonb` para auditoría)
- **Tailwind CSS v4 + DaisyUI v5** — sin `tailwind.config.js`, sin Node (`docs/design_system.md`)
- **Hotwire** (Turbo + Stimulus) vía Import Maps — Tom Select y ApexCharts vendorizados, sin bundler JS
- **Pundit** para autorización — `docs/conventions/authorization.md`
- **RSpec + FactoryBot** — `docs/conventions/testing.md`
- **Kamal 2 + Docker** para deploy — ver `docs/documentation/setup_18_docker.md` (documentado, pendiente de aplicar hasta tener servidor)

## Empezar

```bash
bin/setup
bin/rails db:seed   # roles, permisos y usuarios demo — ver db/seeds.rb
bin/dev
```

Abrí `http://localhost:3000`. Revisá `db/seeds.rb` para las credenciales de
los usuarios demo (uno por rol: super/admin/standard/client/guest).

En desarrollo, `/styleguide` muestra cada componente del design system
(botones, alertas, formularios, charts, Tom Select) con datos de ejemplo.

## Qué incluye

| Módulo | Qué resuelve | Convención |
|---|---|---|
| Autenticación | Generador nativo de Rails 8 + hardening (bloqueo por intentos, rate limiting nativo) | `docs/documentation/setup_06_authentication.md` |
| Autorización | Role/Permission por tablas + Pundit — `<recurso>.view`/`<recurso>.manage` por convención de nombre de policy | `docs/conventions/authorization.md` |
| Componentes | Partials + helpers + Stimulus — sin ViewComponent | `docs/conventions/components.md` |
| Formularios | `AdminFormBuilder` propio + Tom Select + inputs nativos de fecha | `docs/conventions/forms.md` |
| Tablas | `Filterable` (allowlist de scopes, no Ransack) + Pagy 43 | `docs/conventions/tables.md` |
| Charts | Wrapper de ApexCharts, colores del tema en tiempo real | `docs/documentation/setup_11_charts.md` |
| Auditoría | `Auditable` concern + `AuditLog` propio, no la gema `audited` | `docs/conventions/auditing.md` |
| Usuarios | Módulo de referencia — CRUD completo, soft-delete (`deactivated_at`) | `docs/documentation/setup_13_users.md` |

## Testing

```bash
bundle exec rspec
bundle exec rubocop
bin/brakeman
```

O todo junto, en el mismo orden que corre en CI:

```bash
bin/ci
```

Qué se prueba y qué no, y por qué: `docs/conventions/testing.md`.

## Seguridad

CSP estricta, headers de defensa adicionales, `bin/bundler-audit` +
`bin/importmap audit` + Brakeman en cada push. Ver `SECURITY.md` para cómo
reportar una vulnerabilidad, y `docs/documentation/setup_16_security.md`
para el detalle de qué se configuró y por qué.

## Deploy

Dockerfile y Kamal 2 ya están armados (`config/deploy.yml`,
`docker-compose.yml` opcional para Postgres local) pero con placeholders —
no hay ningún servidor real detrás de este repo todavía. Cuando tengas
dominio/servidor, `docs/documentation/setup_18_docker.md` documenta
exactamente qué reemplazar.

## Decisiones de arquitectura

Cada decisión no obvia tiene su registro corto en `docs/adr/` (por qué no
Devise, por qué no Ransack, por qué Auditable propio en vez de una gema,
etc.) con link al razonamiento completo en `docs/documentation/` cuando
hace falta más contexto.

## Licencia

MIT — ver `LICENSE`.
```

**CONTRIBUTING.md** (nuevo):

```markdown
# Contribuir a Admin Gem

## Entorno

```bash
bin/setup
bin/rails db:seed
bin/dev
```

Ruby corre nativo en tu máquina (sin Docker para desarrollo) — ver
`docs/adr/0011-docker-solo-produccion.md`. Si preferís no instalar Postgres
en tu sistema, `docker compose up -d` levanta uno solo para eso.

## Antes de un PR

```bash
bin/ci
```

Corre exactamente lo mismo que CI: rubocop, `bundler-audit`, `importmap
audit`, Brakeman, RSpec, y el chequeo de Zeitwerk — en ese orden, cortando
en el primer paso que falle.

## Estilo de código

Omakase (`rubocop-rails-omakase`) — no hay configuración de estilo propia
más allá de lo que ya define `.rubocop.yml`. Si RuboCop se queja, el fix casi
siempre es `bin/rubocop -A`, no pelear con la regla.

## Convenciones del proyecto

Antes de agregar algo nuevo, revisá si ya existe un patrón para eso —
`docs/conventions/` documenta cada uno con el porqué, no solo el cómo:

- `authorization.md` — cómo declarar un recurso nuevo con Pundit
- `forms.md` — campos del `AdminFormBuilder`, cuándo usar `tom_select`
- `tables.md` — `Filterable`, `components/table`, paginación con Pagy
- `auditing.md` — cómo hacer un modelo auditable
- `testing.md` — qué se prueba y qué no, y por qué
- `components.md` — los tres patrones de partial/helper/Stimulus
- `database.md` — soft-delete, JSONB, migraciones

Si tu cambio introduce una decisión de arquitectura nueva (una dependencia,
un patrón que otros módulos van a copiar), documentala en
`docs/documentation/setup_NN_*.md` siguiendo el formato de las fases
anteriores (Objetivo, Decisiones, Alternativas consideradas, Validaciones) y
agregá un ADR corto en `docs/adr/` si es del tipo de decisión que alguien
va a cuestionar más adelante.

## Tests

Ver `docs/conventions/testing.md` para el criterio completo. En resumen:
autorización y autoprotección siempre se prueban de verdad; helpers sin
lógica de decisión no necesitan spec.

## Commits

Mensajes en español, en imperativo, describiendo qué cambia (`Se agrega...`,
`Se corrige...`) — mismo estilo que el historial existente.
```

**SECURITY.md** (nuevo):

```markdown
# Política de seguridad

## Qué ya está cubierto

- **CSP estricta** (`config/initializers/content_security_policy.rb`) — sin
  `unsafe-inline` en `script-src`; una excepción documentada en `style-src`
  por cómo ApexCharts inyecta su leyenda (ver
  `docs/documentation/setup_16_security.md`, sección "Corrección").
- **Headers adicionales**: `X-Frame-Options: DENY`, `Permissions-Policy`
  restrictiva, `force_ssl`/`assume_ssl` en producción.
- **Autenticación**: generador nativo de Rails 8, bloqueo por intentos
  fallidos, rate limiting nativo (`ActionController::RateLimiting`, sin
  Rack::Attack).
- **Autorización**: Pundit en cada acción de cada controlador real — sin
  excepciones sin `authorize`/`policy_scope`.
- **Escaneo continuo en cada push**: `bin/bundler-audit` (dependencias),
  `bin/importmap audit` (JS vendorizado), Brakeman — los tres corren en
  `bin/ci` y en GitHub Actions.
- **Auditoría**: cada create/update/destroy de un modelo `Auditable` queda
  registrado (quién, qué cambió, IP, user-agent) — `password_digest` nunca
  aparece en un diff, excluido a nivel de modelo.

## Cómo reportar una vulnerabilidad

No abras un issue público. Si encontrás un problema de seguridad, reportalo
por [GitHub Security Advisories](../../security/advisories/new) en este
repositorio, o por correo a quien mantenga el fork/instalación — ese dato
lo completa quien lo despliegue, no el boilerplate en sí.

Incluí: qué encontraste, cómo reproducirlo, y el impacto que ves. Vas a
recibir una respuesta reconociendo el reporte antes de que se haga público
cualquier detalle.

## Versiones soportadas

Este es un boilerplate, no un servicio con versiones publicadas — no aplica
una tabla de "versiones soportadas" tradicional. Cada fork/clone es
responsable de mantener sus propias dependencias actualizadas; Dependabot
ya está configurado (`.github/dependabot.yml`) para avisar de actualizaciones
de gems, GitHub Actions, y (cuando exista) la imagen Docker.
```

**CHANGELOG.md** (nuevo):

```markdown
# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Sin releases todavía — todo vive bajo "Unreleased" hasta el primer tag.

## [Unreleased]

### Added
- Autenticación nativa de Rails 8 con hardening (bloqueo por intentos,
  rate limiting nativo).
- Autorización con Pundit + modelo Role/Permission propio (sin Devise,
  sin CanCanCan).
- Design system con Tailwind v4 + DaisyUI v5, dark/light mode.
- `AdminFormBuilder` propio, Tom Select, inputs nativos de fecha.
- Tabla reutilizable + `Filterable` (allowlist de scopes) + Pagy 43.
- Wrapper de ApexCharts integrado con el tema activo.
- Dashboard con métricas reales y un chart de ejemplo, claramente marcado.
- Módulo de referencia de Usuarios: CRUD completo, soft-delete
  (`deactivated_at`), autoprotección contra autodesactivación.
- Auditoría propia (`Auditable` concern + `AuditLog`), sin la gema `audited`.
- Suite de RSpec + FactoryBot con criterio documentado de qué probar.
- CSP estricta y headers de seguridad adicionales.
- CI unificado (`config/ci.rb` + GitHub Actions): lint, seguridad, tests,
  build.
- Dockerfile + Kamal 2 documentados, listos para aplicar cuando exista
  servidor de destino.

### Security
- `bin/bundler-audit`, `bin/importmap audit` y Brakeman corren en cada push.
- CVE de `resolv` (bundlada con Ruby 3.4.10) parcheada explícitamente en
  el Gemfile hasta que Ruby publique un patch release que la incluya.
```

**docs/adr/README.md** (nuevo — índice):

```markdown
# Architecture Decision Records

Registros cortos de decisiones que alguien nuevo en el proyecto
probablemente cuestione o quiera revisar. Cada uno linkea al documento
completo en `docs/documentation/` para el razonamiento y las alternativas
consideradas en detalle — esto es el resumen ejecutivo, no el reemplazo.

| ADR | Decisión |
|---|---|
| [0001](0001-sin-nodejs.md) | Sin Node.js en el toolchain |
| [0002](0002-postgresql-17.md) | PostgreSQL 17, no 18 |
| [0003](0003-autenticacion-nativa.md) | Generador nativo de Rails 8, no Devise |
| [0004](0004-rate-limiting-nativo.md) | Rate limiting nativo, no Rack::Attack |
| [0005](0005-role-permission-tablas.md) | Role/Permission por tablas, no enum |
| [0006](0006-form-builder-propio.md) | `AdminFormBuilder` propio, no simple_form |
| [0007](0007-inputs-nativos-fecha.md) | Inputs nativos de fecha, no Flatpickr |
| [0008](0008-filterable-no-ransack.md) | `Filterable` con allowlist, no Ransack |
| [0009](0009-pagy.md) | Pagy, no Kaminari/will_paginate |
| [0010](0010-auditable-propio.md) | `Auditable`/`AuditLog` propios, no la gema `audited` |
| [0011](0011-docker-solo-produccion.md) | Docker solo en producción, Ruby nativo en desarrollo |
| [0012](0012-ci-unificado.md) | `config/ci.rb` como única fuente de verdad para CI |
| [0013](0013-db-externa-gestionada.md) | DB externa gestionada, no accessory de Kamal |
| [0014](0014-csp-unsafe-inline-charts.md) | CSP estricta con una excepción documentada para ApexCharts |
```

**docs/adr/0001-sin-nodejs.md** (nuevo):

```markdown
# ADR-0001: Sin Node.js en el toolchain

**Estado:** Aceptada · **Fase:** Setup 2

## Contexto
El stack pedía Tailwind, DaisyUI, Tom Select y ApexCharts — herramientas
tradicionalmente asociadas a un pipeline npm/Node.

## Decisión
Cero Node.js. `tailwindcss-rails` empaqueta el binario standalone de
Tailwind v4 (no un paquete npm). DaisyUI v5 es CSS puro. Tom Select y
ApexCharts se vendorizan vía Import Maps.

## Alternativas consideradas
- `jsbundling-rails`/`cssbundling-rails` con Node real → descartado: sin
  necesidad real, agrega un segundo gestor de paquetes y `node_modules`.

## Consecuencias
Cero `package.json`, cero riesgo de deriva de versiones npm. Si un módulo
futuro necesita algo exclusivo del ecosistema npm, se agrega
`jsbundling-rails` puntual para ese módulo, sin migrar el resto.

Ver `docs/documentation/setup_001_architecture.md` §3.3.
```

**docs/adr/0002-postgresql-17.md** (nuevo):

```markdown
# ADR-0002: PostgreSQL 17, no 18

**Estado:** Aceptada · **Fase:** Setup 3

## Contexto
PostgreSQL 18 ya estaba disponible y estable al momento de esta decisión.

## Decisión
Fijar PostgreSQL 17.x como versión base.

## Alternativas consideradas
- PostgreSQL 18 → descartado por ahora: compatibilidad garantizada en todos
  los proveedores gestionados (RDS, Cloud SQL, Supabase, Render, Fly.io) es
  más valiosa que las novedades de 18, que Rails no explota directamente.

## Consecuencias
El costo de quedarse un escalón atrás es bajo; el beneficio de
compatibilidad universal con proveedores gestionados es alto — relevante
para ADR-0013 (DB externa gestionada).

Ver `docs/documentation/setup_001_architecture.md` §3.2.
```

**docs/adr/0003-autenticacion-nativa.md** (nuevo):

```markdown
# ADR-0003: Generador nativo de Rails 8, no Devise

**Estado:** Aceptada · **Fase:** Setup 6

## Contexto
Devise es el estándar de facto para autenticación en Rails, pero Rails 8
introdujo un generador de autenticación propio (`bin/rails generate
authentication`).

## Decisión
Usar el generador nativo — código propio y legible en vez de una gema con
su propia capa de configuración/convenciones.

## Alternativas consideradas
- Devise → descartado: trae más superficie de configuración de la que este
  boilerplate necesita, y el código generado por Rails 8 ya cubre
  sesiones, recuperación de contraseña y bloqueo por intentos con
  hardening propio.

## Consecuencias
El código de autenticación es 100% legible/modificable sin aprender la API
de una gema — a cambio, features de Devise (2FA, OmniAuth) hay que
agregarlas a mano si aparecen (ver `setup_001_architecture.md` §13:
"decisiones que deliberadamente no implementamos").

Ver `docs/documentation/setup_06_authentication.md`.
```

**docs/adr/0004-rate-limiting-nativo.md** (nuevo):

```markdown
# ADR-0004: Rate limiting nativo, no Rack::Attack

**Estado:** Aceptada (reemplaza una decisión anterior) · **Fase:** Setup 6

## Contexto
El plan original (`setup_001_architecture.md`) fijaba Rack::Attack para
Setup 16 (Security hardening).

## Decisión
No agregar Rack::Attack — `ActionController::RateLimiting`, nativo desde
Rails 7, ya cubre el throttling de login que se necesitaba.

## Alternativas consideradas
- Rack::Attack → descartado: una dependencia menos que mantener para
  resolver algo que el framework ya resuelve.

## Consecuencias
Si en el futuro hace falta throttling más granular (por IP en vez de por
sesión, por ejemplo) en endpoints que no sean de login, ahí sí Rack::Attack
vuelve a ser una opción válida a evaluar puntualmente.

Ver `docs/documentation/setup_06_authentication.md`.
```

**docs/adr/0005-role-permission-tablas.md** (nuevo):

```markdown
# ADR-0005: Role/Permission por tablas, no enum

**Estado:** Aceptada · **Fase:** Setup 7

## Contexto
Un boilerplate necesita RBAC, pero modelarlo con tablas es más trabajo
inicial que un enum de roles en la columna de `users`.

## Decisión
`Role`/`Permission` como tablas reales + Pundit, con el nombre de la
policy determinando el recurso (`RolePolicy` → `roles.view`/`roles.manage`)
sin registro manual por recurso.

## Alternativas consideradas
- Enum de roles en `users.role` → descartado: agregar un permiso nuevo
  exigiría un deploy de código, no un dato.
- CanCanCan → descartado en el ADR original junto con Devise/Ransack, sin
  razón puntual más allá de mantener Pundit como único mecanismo de
  autorización.

## Consecuencias
Más tablas desde el día 1, compensado con seeds simples (5 roles de
ejemplo). Permisos granulares se agregan como datos, no como código.

Ver `docs/documentation/setup_07_authorization.md` y
`docs/conventions/authorization.md`.
```

**docs/adr/0006-form-builder-propio.md** (nuevo):

```markdown
# ADR-0006: `AdminFormBuilder` propio, no simple_form/formtastic

**Estado:** Aceptada · **Fase:** Setup 9

## Contexto
Envolver cada campo en fieldset/label/hint a mano (como en el login de
Setup 6) no escala a un CRUD completo.

## Decisión
Un `FormBuilder` propio (`app/form_builders/admin_form_builder.rb`) que
sobreescribe los métodos estándar de Rails (`text_field`, `select`, etc.)
en vez de introducir una API nueva tipo `f.input`.

## Alternativas consideradas
- simple_form/formtastic → no evaluadas: el objetivo era una pieza propia
  del boilerplate, no una dependencia externa a mantener actualizada.
- Un método único `f.input :attr` que infiere el tipo por columna →
  descartado por ahora: más "magia" de la necesaria: cada método explícito
  (`text_field`, `email_field`...) es más fácil de rastrear cuando algo
  sale mal.

## Consecuencias
Cualquiera que conozca la API estándar de Rails ya sabe usar este builder.
Agregar un tipo de campo nuevo es sobreescribir un método más, siguiendo el
mismo patrón.

Ver `docs/documentation/setup_09_forms.md` y `docs/conventions/forms.md`.
```

**docs/adr/0007-inputs-nativos-fecha.md** (nuevo):

```markdown
# ADR-0007: Inputs nativos de fecha, no Flatpickr

**Estado:** Aceptada · **Fase:** Setup 9

## Contexto
El plan original consideraba Flatpickr para selectores de fecha.

## Decisión
Usar `<input type="date">` nativo para el 90% de los casos. Se reserva un
seam de Stimulus vacío (`data-controller="datepicker"`) para el día que un
caso puntual necesite más (rango visual, calendario inline).

## Alternativas consideradas
- Flatpickr → descartado: sin releases desde 2020, clasificado "Inactive"
  en análisis de salud de dependencias — contradice el propio requisito de
  evitar librerías con mantenimiento dudoso.

## Consecuencias
Cero JS para el caso común, accesibilidad nativa gratis. El seam evita que
decidir una librería de calendario hoy bloquee esta fase — se resuelve
cuando aparezca el caso real, no antes.

Ver `docs/documentation/setup_001_architecture.md` §3.4 y
`docs/documentation/setup_09_forms.md`.
```

**docs/adr/0008-filterable-no-ransack.md** (nuevo):

```markdown
# ADR-0008: `Filterable` con allowlist, no Ransack

**Estado:** Aceptada · **Fase:** Setup 10

## Contexto
Las tablas administrativas necesitan filtros — Ransack es la opción más
común en el ecosistema Rails para esto.

## Decisión
Un concern propio (`Filterable`) donde el controlador declara qué *scopes*
del modelo puede invocar (`filterable_by name: :by_name`) — nunca columnas
crudas desde `params`.

## Alternativas consideradas
- Ransack → descartado: ha tenido advisories de seguridad relacionados con
  exposición de atributos/asociaciones no previstas vía parámetros.

## Consecuencias
Cada filtro nuevo exige declarar un scope explícito en el modelo — más
trabajo por filtro, pero una clase entera de vulnerabilidades de parameter
tampering queda eliminada por diseño, no por configuración.

Ver `docs/documentation/setup_10_indexes.md` y `docs/conventions/tables.md`.
```

**docs/adr/0009-pagy.md** (nuevo):

```markdown
# ADR-0009: Pagy, no Kaminari/will_paginate

**Estado:** Aceptada · **Fase:** Setup 10

## Contexto
Paginación es una necesidad transversal a toda tabla administrativa.

## Decisión
Pagy (`~> 43.0`) — más liviano que las alternativas, sin dependencias,
activamente mantenido (v43 es un rediseño completo reciente).

## Alternativas consideradas
- Kaminari/will_paginate → no evaluadas en profundidad: Pagy ya estaba
  identificado como la opción más liviana desde el ADR original.

## Consecuencias
La v43 cambió la API completa respecto a versiones anteriores
(`pagy(:offset, scope)` en vez de `pagy(scope)`, `@pagy.series_nav` en vez
de `pagy_nav`) — cualquier tutorial pre-v43 que se consulte después va a
estar desactualizado.

Ver `docs/documentation/setup_10_indexes.md`.
```

**docs/adr/0010-auditable-propio.md** (nuevo):

```markdown
# ADR-0010: `Auditable`/`AuditLog` propios, no la gema `audited`

**Estado:** Aceptada · **Fase:** Setup 14

## Contexto
Se necesitaba dejar rastro de quién cambió qué — `audited` es la gema más
común para esto en Rails.

## Decisión
Un concern propio + un modelo `AuditLog` con `resource` polimórfico y el
diff vía `ActiveModel::Dirty`, guardado en JSONB.

## Alternativas consideradas
- Gema `audited` → descartada por ahora: el esquema propio (actor, acción,
  recurso polimórfico, diff) es equivalente en concepto, así que migrar a
  `audited` después —si hiciera falta compliance más pesado— sería una
  migración de datos, no un rediseño.

## Consecuencias
Menos features de fábrica (sin restauración point-in-time, por ejemplo),
compensado por control total sobre qué se excluye del diff
(`audit_excludes :password_digest`).

Ver `docs/documentation/setup_14_audit.md` y `docs/conventions/auditing.md`.
```

**docs/adr/0011-docker-solo-produccion.md** (nuevo):

```markdown
# ADR-0011: Docker solo en producción, Ruby nativo en desarrollo

**Estado:** Aceptada · **Fase:** Setup 2 / Setup 18

## Contexto
Docker podría usarse tanto para desarrollo como para producción.

## Decisión
Ruby corre nativo en la máquina del desarrollador (`bin/dev`). Docker
aparece recién en Setup 18, para producción vía Kamal — opcionalmente,
`docker-compose.yml` levanta solo Postgres en local si alguien prefiere no
instalarlo en su sistema.

## Alternativas consideradas
- Dev Containers / todo en Docker local → descartado: prioriza DX nativa
  (arranque más rápido, menos capas) sobre paridad dev/prod exacta.

## Consecuencias
Onboarding más simple para quien ya tiene Ruby instalado; quien prefiera
contenedores para todo puede adaptar el `docker-compose.yml` existente.

Ver `docs/documentation/setup_001_architecture.md` §10 y
`docs/documentation/setup_18_docker.md`.
```

**docs/adr/0012-ci-unificado.md** (nuevo):

```markdown
# ADR-0012: `config/ci.rb` como única fuente de verdad para CI

**Estado:** Aceptada · **Fase:** Setup 17

## Contexto
Rails 8.1 genera tanto un workflow tradicional de GitHub Actions como
`config/ci.rb` (`ActiveSupport::ContinuousIntegration`, corrible local vía
`bin/ci`) — ambos con pasos equivalentes.

## Decisión
`config/ci.rb` define la pipeline una sola vez; `.github/workflows/ci.yml`
es un wrapper delgado que solo levanta el servicio de Postgres y corre
`bin/ci`.

## Alternativas consideradas
- Mantener las dos definiciones en paralelo → descartado: cualquier cambio
  futuro habría que hacerlo dos veces, en dos lenguajes, con riesgo real de
  que se desincronicen.

## Consecuencias
Correr `bin/ci` localmente reproduce exactamente lo que corre en GitHub —
sin sorpresas de "en mi máquina pasa". Trade-off: la pipeline es secuencial
(más lenta en el caso feliz) en vez de jobs en paralelo.

Ver `docs/documentation/setup_17_ci_cd.md`.
```

**docs/adr/0013-db-externa-gestionada.md** (nuevo):

```markdown
# ADR-0013: DB externa gestionada, no accessory de Kamal

**Estado:** Aceptada · **Fase:** Setup 18

## Contexto
Kamal permite correr Postgres como un accessory container en el mismo
servidor que la app.

## Decisión
`config/deploy.yml` asume una base de datos externa gestionada
(RDS/Cloud SQL/Supabase/Render/Fly.io) vía `DATABASE_HOST` — coherente con
la razón detrás de ADR-0002 (PG 17 elegido pensando en proveedores
gestionados). Un accessory de Postgres self-hosted queda documentado como
alternativa, comentado, no como default.

## Alternativas consideradas
- Accessory de Postgres en el mismo servidor → válido, dejado como opción
  para quien prefiera no depender de un tercero — no es el default.

## Consecuencias
La capa de datos no vive ni escala junto con el contenedor stateless de la
app — separación que la mayoría de los proveedores gestionados ya resuelve
mejor que un contenedor casero (backups, failover).

Ver `docs/documentation/setup_18_docker.md`.
```

**docs/adr/0014-csp-unsafe-inline-charts.md** (nuevo):

```markdown
# ADR-0014: CSP estricta con una excepción documentada para ApexCharts

**Estado:** Aceptada (con corrección post-implementación) · **Fase:** Setup 16

## Contexto
La CSP inicial (Setup 16) fijó `style-src 'self'` sin excepciones. En uso
real, ApexCharts rompía su propia leyenda: inyecta un `<style>` inline
dentro de un `<foreignObject>` del SVG en cada render, código interno de la
librería, no del proyecto.

## Decisión
Relajar únicamente `style-src` a `'self' 'unsafe-inline'`. `script-src` se
mantiene estricto — ahí sí importa: inyección de script es un riesgo mucho
mayor que el de estilo, y no hay ningún tercero que necesite inline ahí.

## Alternativas consideradas
- Hashear el `<style>` inline específico (CSP soporta `sha256-...`) →
  descartado: el bundle minificado de ApexCharts cambia con cada
  actualización de versión, así que el hash se rompe silenciosamente en
  cada upgrade de la librería.
- CSP distinta por controlador (solo relajar donde hay charts) →
  descartado: agrega la pregunta de "¿por qué esta página tiene una CSP
  distinta?" para mitigar un riesgo (inyección de estilo) que ya es bajo.

## Consecuencias
`style-src` queda menos estricto de lo ideal, documentado y acotado a un
motivo concreto — no es un "por las dudas" genérico.

Ver `docs/documentation/setup_16_security.md`, sección "Corrección
(post-implementación)".
```

## Validaciones

```bash
git mv docs/setup_13_users.md docs/documentation/setup_13_users.md
```

Revisá que los links de `docs/adr/README.md` a `docs/documentation/setup_NN_*.md` resuelvan bien contra los nombres reales que tenés (`setup_10_indexes.md`, `setup_14_audit.md`, etc. — usé esos nombres, no los que yo había sugerido originalmente).