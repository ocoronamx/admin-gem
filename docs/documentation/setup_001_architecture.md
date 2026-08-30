# ADR-0000 — Arquitectura del Boilerplate Administrativo (Ruby on Rails)

**Estado:** Propuesta — pendiente de tu aprobación antes de iniciar la Fase 1
**Fecha:** 2026-08-29
**Alcance:** Base reutilizable para múltiples aplicaciones administrativas/empresariales, no una app de negocio específica.

---

## 1. Objetivos

Construir una base Rails que pueda sostener múltiples aplicaciones administrativas durante años, priorizando en este orden: seguridad → calidad arquitectónica → mantenibilidad → escalabilidad → DX → UX → rendimiento → consistencia visual → facilidad de extensión → longevidad.

La medida de éxito no es "que funcione hoy", sino que un equipo senior distinto al que lo construyó pueda entenderlo, extenderlo y actualizarlo dentro de 3-5 años sin reescribirlo.

## 2. Non-goals (explícitamente fuera de alcance por ahora)

No vamos a construir, todavía, ninguno de estos puntos — pero la arquitectura no los bloquea a futuro (ver sección 12):

- Una aplicación de negocio concreta (esto es un template).
- Multi-tenancy.
- SSO / OAuth externo.
- 2FA.
- API pública versionada.
- Microservicios o extracción de servicios.
- Internacionalización más allá de `es`/`en`.
- App móvil nativa.
- Redis / Sidekiq (Solid Queue cubre el caso inicial).
- ViewComponent como gema (partials + helpers son suficientes hoy).
- Ransack u otra gema de filtrado "mágico" (razones de seguridad, ver §8.4).

## 3. Evaluación del stack solicitado y versiones recomendadas

Verifiqué el estado actual (agosto 2026) de cada pieza del stack antes de fijar versiones, porque un boilerplate de larga vida no debería nacer sobre una versión ya obsoleta ni sobre la más reciente sin madurar. Resumen:

| Tecnología | Solicitada | Recomendación | Motivo |
|---|---|---|---|
| Ruby | — | **3.4.x** (alternativa viable: 4.0.x) | Ver §3.1 |
| Rails | — | **8.1.x** | Última serie estable; trae Solid Queue/Cache/Cable, generador de auth propio, Kamal 2 y Dockerfile por defecto |
| PostgreSQL | — | **17.x** (alternativa viable: 18.x) | Ver §3.2 |
| Node.js | — | **Ninguno** | Ver §3.3 — decisión importante |
| Tailwind CSS | Sí | **v4.3.x** vía `tailwindcss-rails` (CLI standalone) | CSS-first, sin `tailwind.config.js`, sin Node |
| DaisyUI | Sí | **v5.x** vía `@plugin "daisyui"` en CSS | v5 es CSS puro, cero dependencias, compatible con Tailwind v4 |
| Tom Select | Sí | vía `tom-select-rails` (~> 2.5) + Importmap | Mantenido activamente, sin necesidad de bundler JS |
| Flatpickr | Sí | **Reemplazo recomendado** — ver §3.4 | El proyecto original está inactivo desde 2020 |
| ApexCharts | Sí | **Fijar una v6.x estable**, evaluar v7 más adelante | v7.0.0 se publicó hace solo días; demasiado reciente para un boilerplate |
| Pagy | Sí | **~> 43.0** | Rediseño total ("leap version"), requiere Ruby ≥ 3.3, activamente mantenido |
| Pundit | Sí | **~> 2.5** | Estable, maduro, sin cambios drásticos recientes |
| Background jobs | — | **Solid Queue** (default Rails 8) | Sin Redis; persiste en PostgreSQL |
| Cache | — | **Solid Cache** (default Rails 8) | Igual razón |
| Autenticación | — | **Generador nativo de Rails 8** (`bin/rails generate authentication`) | Código propio, no gema externa — ver §7 |
| Testing | — | **RSpec + FactoryBot + Capybara** (a confirmar contigo) | Ver §3.5 |
| CI | — | **GitHub Actions** | Ubicuo, gratuito para repos, YAML portable |
| Deployment | — | **Docker + Kamal 2** | Default de Rails 8, sin lock-in de PaaS |

### 3.1 Ruby: 3.4 vs 4.0

Ruby 4.0 se publicó el 25 de diciembre de 2025 como parte de la tradición de releases de Navidad, coincidiendo con el 30 aniversario del lenguaje. A pesar del salto de versión mayor, el propio equipo de Ruby diseñó el release para ser mayormente compatible con el código fuente existente, y no sigue versionado semántico estricto — el salto de número es más simbólico que disruptivo. A la fecha ya lleva seis releases de parche (4.0.6, 14 de julio de 2026), lo que indica una curva de estabilización razonable.

Dicho esto, **recomiendo Ruby 3.4.x como base por defecto**, porque:
- El cambio de *soname* en 4.0 obliga a reconstruir gemas con extensiones nativas (ej. `pg`, `bcrypt`), lo que introduce fricción operativa en imágenes Docker y en el pipeline de CI que no aporta valor a un boilerplate recién nacido.
- Ruby 3.4 sigue en mantenimiento normal (con soporte hasta aproximadamente 2028) y tiene el ecosistema de gemas más ampliamente probado.
- No perdemos nada arquitectónicamente relevante: las novedades de 4.0 (Ruby Box, ZJIT) son experimentales y no aptas para producción todavía.

Si prefieres empezar directamente en Ruby 4.0 para no tener que migrar en 12-18 meses, es una decisión razonable — lo delego a tu confirmación (pregunta 1, al final de este documento).

### 3.2 PostgreSQL: 17 vs 18

PostgreSQL 18 lleva en el mercado desde septiembre de 2025 y ya está en su versión 18.6, por lo que es una opción sólida. Aun así, recomiendo **PostgreSQL 17.x** como versión por defecto porque tiene una ventana de soporte más amplia por delante y compatibilidad garantizada en absolutamente todos los proveedores gestionados (RDS, Cloud SQL, Supabase, Render, Fly.io, etc.), algunos de los cuales tardan más en certificar la última versión mayor. La capa de acceso a datos de Rails no depende de ninguna característica exclusiva de PG 18, así que el costo de mantenerse un escalón atrás es bajo y el beneficio de compatibilidad es alto.

### 3.3 Decisión clave: sin Node.js en el toolchain

Verifiqué que **ninguna pieza del stack solicitado requiere Node.js**:

- `tailwindcss-rails` (gema oficial de Rails) empaqueta el ejecutable standalone de Tailwind v4 a través de `tailwindcss-ruby` — es un binario nativo por plataforma, no un paquete npm.
- DaisyUI v5 es CSS puro (cero dependencias JS) que se activa con `@plugin "daisyui";` directamente en el archivo CSS de entrada, sin `tailwind.config.js`.
- Tom Select se puede servir vía **Import Maps** (pin a una copia vendored o a un CDN), igual que ApexCharts. Ninguno de los dos exige un paso de build.
- Hotwire (Turbo + Stimulus) ya viene integrado en Rails vía Import Maps.

Esto significa: **cero `package.json`, cero `node_modules`, cero riesgo de deriva de versiones de npm**. Es una simplificación importante para la longevidad del proyecto (menos superficie de dependencias que actualizar, sin dos gestores de paquetes en paralelo) y está totalmente alineado con tu punto 14 ("no agregar Node/Webpack/Vite simplemente porque es lo moderno"). Si en el futuro un módulo necesita algo que solo existe en el ecosistema npm (p. ej. un editor WYSIWYG complejo), se evalúa puntualmente con `jsbundling-rails` para ese módulo, sin migrar todo el proyecto.

### 3.4 Hallazgo importante: Flatpickr está prácticamente abandonado

Antes de fijarlo en el stack, verifiqué el estado de mantenimiento del proyecto `flatpickr/flatpickr` (la librería original, no wrappers de framework). Los hallazgos:

- No ha publicado una versión nueva en npm desde diciembre de 2020.
- Un análisis de salud de dependencias (Snyk) clasifica su mantenimiento como **"Inactive"**, señalando que no ha tenido releases en los últimos 12 meses.
- Hay hilos abiertos en su propio repositorio desde 2021 preguntando si el proyecto sigue vivo, sin una respuesta oficial de continuidad.

Esto contradice directamente uno de tus propios requisitos ("evitar librerías abandonadas o con mantenimiento dudoso"), así que te propongo un cambio justificado en vez de generar el boilerplate con una dependencia congelada desde hace 5+ años:

**Propuesta:** usar los inputs nativos de HTML5 (`type="date"`, `type="datetime-local"`, `type="time"`) como opción por defecto para el 90% de los formularios administrativos, estilizados con Tailwind/DaisyUI. Ventajas: cero JavaScript, cero mantenimiento, accesibilidad nativa, selector nativo en móvil, funcionan perfectamente con Turbo/Stimulus.

Para los casos donde de verdad se necesite algo que el input nativo no cubre (rango visual de fechas, calendario inline embebido, selección múltiple visual), definiremos una interfaz Stimulus delgada (`data-controller="datepicker"`) de modo que en la Fase 8 se pueda enchufar una librería concreta (evaluando en ese momento la opción más sana del ecosistema — por ejemplo Air Datepicker, que sigue publicando versiones, aunque con cadencia lenta) sin que el resto del sistema dependa de esa elección. Esto es exactamente el tipo de "explicit over magic + aislar la volatilidad" que pediste en los principios arquitectónicos.

Quiero tu confirmación explícita sobre este punto porque desvía de lo que pediste literalmente (pregunta 3, al final).

### 3.5 RSpec vs Minitest

Ambas son opciones legítimas. Minitest es el default de Rails (cero dependencias adicionales, más rápido de arrancar). RSpec tiene una sintaxis más legible para specs de políticas de autorización y un ecosistema de matchers (shoulda-matchers, pundit-matchers) que encaja muy bien con lo que vamos a construir (Pundit, políticas, escenarios de autorización). Mi recomendación es **RSpec**, pero es una preferencia razonable en cualquier dirección — te pregunto al final (pregunta 4).

---

## 4. Arquitectura general

```text
Browser (HTML + Turbo/Stimulus, sin build JS)
   │
   ▼
Rails (Puma)
   ├── Controllers        → orquestan, delegan autorización y lógica
   ├── Policies (Pundit)  → "¿puede este usuario hacer esto?"
   ├── Models             → reglas de negocio + validaciones + scopes
   ├── Services           → SOLO cuando una operación cruza >1 modelo
   │                         o tiene efectos secundarios (mailer, job, API externa)
   ├── Queries            → SOLO cuando un filtro/reporte es reutilizado
   │                         en 2+ lugares y no cabe bien como scope
   ├── Jobs (Solid Queue) → trabajo asíncrono (mailers, auditoría pesada, reportes)
   ├── Mailers            → notificaciones transaccionales
   └── Views (ERB + partials + Stimulus)
        │
        ▼
   PostgreSQL (datos, cache, colas — un solo motor)
```

Mantengo tu propuesta casi intacta. El único matiz es que **Services y Queries son la excepción, no la norma**: la mayoría de los controladores de un CRUD administrativo no necesitan ninguno de los dos si el modelo está bien diseñado. Esto evita el antipatrón "un Service por cada acción" que mencionaste explícitamente que no quieres.

## 5. Estructura de directorios propuesta

```text
app/
├── controllers/
│   ├── concerns/
│   └── admin/              # namespace para separar futuras áreas (admin/, api/, etc.)
├── models/
│   └── concerns/           # Auditable, SoftDeletable (si aplica), etc.
├── policies/
│   └── application_policy.rb
├── services/                # vacío al inicio; se puebla solo cuando aparece la necesidad real
├── queries/                 # idem
├── jobs/
├── mailers/
├── helpers/
├── views/
│   ├── layouts/
│   ├── components/          # partials reutilizables: _button, _card, _table, _modal...
│   └── <módulo>/            # una carpeta por módulo funcional (users/, dashboard/...)
├── javascript/
│   └── controllers/         # Stimulus
└── assets/
    └── stylesheets/
        └── application.tailwind.css   # @import "tailwindcss"; @plugin "daisyui"; @theme {...}

config/
├── initializers/
└── locales/
    ├── es.yml
    └── en.yml

db/
├── migrate/
└── seeds.rb                 # datos de demo, claramente marcados como tales

spec/ (o test/, según decisión de §3.5)
docs/
└── adr/                      # este documento y los que sigan
```

Esta estructura es Rails "de manual" a propósito: cualquier desarrollador Rails puede orientarse sin leer documentación adicional. La única adición no estándar es `app/views/components/`, que es donde vivirá el design system (botones, cards, tablas, badges, etc. como partials parametrizados vía `render "components/button", variant: :primary`).

## 6. Estrategia de autenticación (§7 de tu prompt)

**Decisión:** usar el generador de autenticación nativo de Rails 8 (`bin/rails generate authentication`) en vez de Devise.

Justificación:
- Genera código Ruby plano dentro de tu propia app (`app/models/user.rb`, `app/models/session.rb`, `app/controllers/sessions_controller.rb`, etc.), no una gema opaca. Esto es coherente con "Explicit over Magic" y con tu prioridad de mantenibilidad a largo plazo: no hay que esperar a que un mantenedor externo publique un fix para actualizar a la próxima versión de Rails.
- Menos superficie de dependencias — Devise es una gema grande, con su propio ciclo de releases, que históricamente ha sido un cuello de botella en migraciones mayores de Rails.
- Cubre lo esencial (sesiones basadas en cookies firmadas, `has_secure_password`, recuperación de contraseña) y es trivialmente extensible para lockout, rate limiting y políticas de contraseña, que añadiremos explícitamente en la Fase 5/15 con Rack::Attack y validaciones propias.

**Autenticación vs Autorización**, tal como pediste:
- *Authentication* responde "¿quién eres?" → generador nativo de Rails, sesiones, bcrypt.
- *Authorization* responde "¿qué puedes hacer?" → Pundit, exclusivamente. Cero `if current_user.admin?` disperso en vistas o controladores.

## 7. Estrategia de autorización (§8 de tu prompt)

Modelo de datos: `User → Role → Permissions` mediante una tabla de unión, en vez de un enum fijo de roles. Razón: un enum (`role: :admin | :editor | :viewer`) es más simple hoy, pero obliga a tocar código Ruby cada vez que se necesita un permiso nuevo. Un modelo `Role` con `Permission`s asociadas permite crear/ajustar roles desde datos (seeds o, más adelante, una pantalla de administración) sin desplegar código. Esto es exactamente el tipo de decisión que "facilita la evolución sin sobre-construir hoy" (tu sección 32): no vamos a construir una UI de gestión de permisos ahora, pero el esquema de datos ya lo permite.

Cada policy hereda de una `ApplicationPolicy` con los verbos estándar (`index?`, `show?`, `create?`, `update?`, `destroy?`) resueltos consultando los permisos del rol, y usa `Policy::Scope` para filtrar colecciones (nunca filtros de visibilidad hechos a mano en el controlador).

## 8. Notas de seguridad relevantes para esta fase

(El detalle completo se trabaja en la Fase 15, pero estas decisiones de fondo ya afectan el modelado de datos de la Fase 2, así que las dejo fijadas ahora):

1. **Claves primarias:** `bigint` autoincremental por defecto (rendimiento, simplicidad, índices más pequeños). Para recursos expuestos en URLs públicas donde la enumerabilidad del ID sea un riesgo real (IDOR), añadimos una columna `public_id` (UUID) con índice único, en vez de cambiar el tipo de PK global — así no pagamos el costo de rendimiento de UUID como PK en todas las tablas.
2. **JSONB:** solo para datos verdaderamente no estructurados o de forma variable (ej. metadata de auditoría, configuración de un módulo). Nunca como sustituto de columnas y relaciones cuando el dato tiene una forma conocida y consultable.
3. **Rate limiting / fuerza bruta:** `Rack::Attack` (activamente mantenido, estándar de facto en el ecosistema Rails) para throttling de login y endpoints sensibles.
4. **Filtrado de tablas administrativas:** en vez de una gema de "filtrado mágico por parámetros" (tipo Ransack, que ha tenido advisories de seguridad relacionados con exposición de atributos/asociaciones no previstas vía parámetros), usaremos scopes de ActiveRecord explícitos + una lista blanca de columnas filtrables por controlador. Es un poco más de código, pero elimina una clase entera de vulnerabilidades de "parameter tampering" por diseño.
5. **Auditoría:** un `Auditable` concern + modelo `AuditLog` propio (usuario, acción, recurso, resource_id, timestamp, IP, user agent, diff de cambios vía `ActiveModel::Dirty`) en vez de una gema completa como `audited`. Es suficiente para lo que pides en tu sección 19 y evita otra dependencia con su propio ciclo de vida. Si más adelante se necesita historial completo con restauración punto-en-el-tiempo, se evalúa `audited` como mejora incremental, no como base.

## 9. Estrategia de componentes de UI (§15 de tu prompt)

| Tipo de contenido | Dónde vive |
|---|---|
| Elemento visual puro, reutilizado en 2+ vistas (botón, badge, card) | Partial en `views/components/` |
| Lógica de presentación sin estado (formatear una fecha, una etiqueta de status) | Helper |
| Interactividad en el navegador (dropdown, modal, autoguardado) | Stimulus controller |
| Regla de negocio o decisión ("¿puede editar esto?") | Policy o modelo — nunca en la vista |
| Composición de 3+ componentes con lógica propia de layout | Se evalúa ViewComponent en ese momento puntual, no antes |

No introducimos la gema ViewComponent en el arranque. Partials parametrizados + helpers + Stimulus cubren el 100% de lo pedido en tu sección 6/17 sin añadir una capa de abstracción adicional. Si en la Fase 7 (al construir el catálogo real de componentes) aparece un caso genuinamente doloroso con partials (lógica condicional compleja, necesidad de testing unitario del componente en aislamiento), lo revisamos con datos concretos en la mano, no especulativamente.

## 10. Estrategia de deployment

Rails 8 genera por defecto un `Dockerfile` de producción y viene preparado para Kamal 2 (deploy a cualquier VPS vía SSH + Docker, sin depender de un PaaS propietario). Esto encaja con tu petición de evitar acoplar el boilerplate a un proveedor específico. Docker se usa en local **solo** para levantar PostgreSQL (vía `docker-compose`, opcional) — Ruby corre nativo en la máquina del desarrollador para minimizar fricción de DX, tal como pediste en tu sección 26.

## 11. Riesgos técnicos

| Riesgo | Mitigación |
|---|---|
| Ecosistema JS (Tom Select, ApexCharts) vía Import Maps puede volverse incómodo si un módulo futuro necesita un bundler real | Aislado por diseño: se añade `jsbundling-rails` solo para ese módulo puntual, no se migra todo el proyecto |
| ApexCharts acaba de saltar a v7 días antes de esta propuesta | Fijamos una v6.x conocida-estable en Fase 10, no la v7 recién publicada |
| Rails 8.1 es relativamente reciente (menos "battle-tested" que 7.2 en producción real) | 7.2 sigue soportado como alternativa si prefieres más cautela; lo dejo a tu criterio |
| Modelo Role/Permission puede parecer sobre-ingeniería para un boilerplate simple | Se compensa con seeds simples (2-3 roles de ejemplo) — la complejidad está en el esquema, no en el uso diario |
| Auditoría propia en vez de gema puede quedarse corta si crecen los requisitos de compliance | Diseñada para poder migrar datos a `audited` sin reescritura si el requisito aparece |

## 12. Trade-offs y qué facilita qué evolución futura (§32 de tu prompt)

| Decisión hoy | Qué facilita mañana |
|---|---|
| Role/Permission en tablas, no enum | Añadir permisos granulares sin deploy de código |
| `public_id` UUID opcional en vez de UUID global | Migrar recursos puntuales a IDs no enumerables (ej. al exponer una API) sin re-clave-primaria toda la BD |
| Sin Redis desde el día 1 (Solid Queue/Cache) | Si el volumen de jobs crece mucho, migrar a Sidekiq+Redis es un cambio acotado a `config/queue.yml` y el adapter, no una reescritura |
| Sin Node.js | Si un módulo futuro necesita SPA-like interactivity pesada, se añade `jsbundling-rails` solo ahí, sin tocar el resto |
| Policies + Scopes desde el inicio | Multi-tenancy futura se modela como un scope adicional en cada Policy::Scope, no como una reescritura de autorización |
| Auditoría propia con esquema simple | Migrar a un gem de compliance más pesado es un import de datos, no un rediseño |
| bigint como PK por defecto | Sharding o partición futura de tablas grandes no se complica por UUIDs innecesarios en tablas internas |

## 13. Decisiones que deliberadamente NO implementamos todavía

- Multi-tenancy (el modelo de datos no lo impide, pero no se construye ahora).
- SSO/OAuth (Pundit y el modelo de `User` no tienen ningún acoplamiento que lo bloquee después).
- 2FA (se añadiría como columna en `User` + un flujo adicional en sessions_controller, sin rediseño).
- API pública (los controladores ya separan bien lógica de presentación, así que exponer JSON después es incremental).
- ViewComponent, Ransack, Devise, Redis/Sidekiq — evaluados y descartados por ahora, no por desconocimiento sino por decisión explícita (ver secciones anteriores).

---

## 14. Roadmap propuesto

Mantengo básicamente tu secuencia original porque ya es sólida; solo la anoto con dónde se resuelven las decisiones abiertas de este documento.

```text
Fase 0  — Arquitectura                         ← este documento
Fase 1  — Inicialización Rails                 (Ruby/Rails elegidos, Gemfile base, RuboCop, git)
Fase 2  — Base de datos                        (convenciones, PKs, índices, extensiones Postgres)
Fase 3  — Frontend / Design System              (Tailwind v4 + DaisyUI v5, tokens, dark/light mode)
Fase 4  — Layout administrativo                 (sidebar, header, breadcrumbs, mobile nav)
Fase 5  — Authentication                        (generador nativo Rails 8 + hardening)
Fase 6  — Authorization                         (Pundit + Role/Permission)
Fase 7  — Componentes                           (partials/helpers/Stimulus del design system)
Fase 8  — Forms                                 (form builder, Tom Select, decisión final de date input)
Fase 9  — Tables / Filtros / Pagy               (tabla reutilizable, filtros por allowlist)
Fase 10 — Charts                                (wrapper ApexCharts, versión fijada aquí)
Fase 11 — Dashboard                             (demo data, claramente marcada)
Fase 12 — Usuarios                              (módulo de referencia)
Fase 13 — Auditoría                             (Auditable concern + AuditLog)
Fase 14 — Testing                               (RSpec/Minitest según tu decisión)
Fase 15 — Security hardening                    (Rack::Attack, CSP, headers, Brakeman)
Fase 16 — CI/CD                                 (GitHub Actions: lint → security → tests → build)
Fase 17 — Docker / Deployment                   (Dockerfile + Kamal 2)
Fase 18 — Documentation                         (README, CONTRIBUTING, SECURITY, CHANGELOG, docs/adr/)
Fase 19 — Revisión final de arquitectura
```

Cada fase, al cerrarse, deja el proyecto en un estado que arranca (`rails server`), pasa sus tests y es revisable en un PR razonable — no avanzamos a la siguiente sin tu aprobación explícita, tal como pediste.

---

## 15. Preguntas que necesito que confirmes antes de la Fase 1

1. **Ruby:** ¿3.4.x (recomendado, máxima compatibilidad de gemas) o 4.0.x (más nuevo, ya con 6 parches, pero exige rebuilds de gemas nativas)?
2. **PostgreSQL:** ¿17.x (recomendado, soporte universal en proveedores gestionados) o 18.x (más reciente, ya estable)?
3. **Flatpickr → inputs nativos:** ¿confirmas el cambio explicado en §3.4 (justificado por abandono del proyecto), o prefieres mantener Flatpickr asumiendo ese riesgo de mantenimiento?
4. **Testing:** ¿RSpec (recomendado) o Minitest (default de Rails, cero dependencias extra)?
5. **ApexCharts:** ¿de acuerdo con fijar una v6.x estable en vez de la v7.0.0 recién publicada?
6. **Auditoría:** ¿concern/modelo propio ligero (recomendado) o la gema `audited` desde el inicio?

### Respuestas

1. Ruby: 3.4.x
2. PostgreSQL: 17.x
3. Flatpickr: No, mejor usar inputs nativos
4. Testing: RSpec
5. ApexCharts: v6.x
6. Auditoría: concern/modelo propio ligero
