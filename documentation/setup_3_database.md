# Setup: Database

## Objetivo

Fijar las convenciones de base de datos que va a heredar todo módulo futuro (naming, claves, índices, nulabilidad, JSONB, soft-delete, migraciones seguras), habilitar las extensiones de PostgreSQL que necesitaremos, y endurecer database.yml para producción. No creamos ninguna tabla de negocio todavía — eso llega con Usuarios en la Fase 5.

## Decisiones arquitectónicas

* PK: bigint autoincremental por defecto (ya fijado en el ADR). El patrón public_id (UUID) para recursos expuestos en URL es opt-in por modelo y se implementa la primera vez que haga falta (Fase 5); aquí solo habilitamos la extensión de Postgres que lo hace posible.
* Soft delete: NO se implementa un mecanismo genérico (nada de discard/paranoia para todas las tablas). Cada módulo que necesite "desactivar sin borrar" (ej. Usuarios) añade su propia columna explícita (deactivated_at:datetime) cuando llegue ese módulo. Un soft-delete global esconde bugs de scope (es fácil olvidar .kept/.with_deleted en un query nuevo) y no todas las tablas necesitan semántica de papelera.
* JSONB: solo para datos de forma variable/desconocida (metadata de auditoría en Fase 13, configuración libre por módulo). Prohibido como sustituto de columnas/relaciones cuando el dato tiene forma conocida.
* Extensiones de Postgres: pgcrypto (habilita gen_random_uuid(), para cuando lleguen los public_id) y citext (comparación case-insensitive, la usaremos en users.email en la Fase 5).
* database.yml: pool y timeouts parametrizados por variables de entorno en producción, sin tocar development/test.


## Comando

```bash
bin/rails generate migration EnablePostgresExtensions
```

## Archivos

db/migrate/XXXXXXXXXXXXXX_enable_postgres_extensions.rb

```ruby
class EnablePostgresExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto"
    enable_extension "citext"
  end
end
```

config/database.yml — ajusta el bloque production (deja development/test como los generó Rails):

```yaml
production:
  primary: &primary_production
    <<: *default
    database: admin_gem_production
    username: admin_gem
    password: <%= ENV["ADMIN_GEM_DATABASE_PASSWORD"] %>
    host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
    pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>
    connect_timeout: 5
    variables:
      statement_timeout: "15s"
  cache:
    <<: *primary_production
    database: admin_gem_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    database: admin_gem_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    database: admin_gem_production_cable
    migrations_paths: db/cable_migrate
```

statement_timeout corta cualquier query que se cuelgue más de 15s — evita que una consulta mal escrita en un módulo futuro deje sin conexiones al resto de la app.

docs/conventions/database.md (nuevo):

```markdown
# Convenciones de base de datos — admin-gem

## Claves primarias
- `bigint` autoincremental por defecto en toda tabla nueva.
- UUID solo como columna adicional `public_id` (no como PK) en recursos
  expuestos en URLs públicas donde la enumerabilidad sea un riesgo real (IDOR).
  Se genera con `gen_random_uuid()` (extensión `pgcrypto`).

## Nulabilidad
- Toda columna es `null: false` salvo que el caso de uso justifique lo
  contrario. La justificación se escribe como comentario en la migración.

## Índices
- Toda foreign key lleva índice (Rails lo hace automático vía `t.references`).
- Toda columna usada en `WHERE`/`ORDER BY` con frecuencia real (no especulativa)
  lleva índice, añadido en su propia migración.
- En tablas con datos reales (no vacías), los índices se crean con
  `disable_ddl_transaction!` + `algorithm: :concurrently`.

## Unicidad
- Unicidad de negocio (ej. email) se garantiza en dos capas: validación en el
  modelo (UX) + índice único en BD (integridad real). Nunca solo una de las dos.

## JSONB
- Solo para datos de forma variable o desconocida de antemano.
- Nunca como sustituto de columnas/relaciones cuando el dato tiene forma conocida.

## Soft delete
- No hay mecanismo genérico. Cada módulo que necesite "desactivar sin borrar"
  añade su propia columna explícita (ej. `deactivated_at:datetime`) y sus
  propios scopes (`active`, `deactivated`). Ver Usuarios (Fase 12) como referencia.

## Migraciones
- Una migración = un cambio conceptual. No mezclar cambio de esquema con
  backfill de datos en la misma migración.
- Todo `change` debe ser reversible; si no lo es, se implementan `up`/`down`
  explícitos con un comentario explicando por qué.
```

## Verificación de consistencia

Tras migrar, db/schema.rb debe listar enable_extension "citext" y enable_extension "pgcrypto" en el bloque ActiveRecord::Schema. Si falta alguna, el db:migrate no corrió limpio.

## Validaciones

```bash
bin/rails db:migrate
# bin/rails runner 'puts ActiveRecord::Base.connection.extensions.keys'
bin/rails runner 'puts ActiveRecord::Base.connection.extensions'
# => debe incluir "pgcrypto" y "citext"
bundle exec rubocop -a
```

## Seguridad

* statement_timeout mitiga un vector de disponibilidad (consultas descontroladas).
* citext en emails previene bypass de unicidad por mayúsculas/minúsculas — relevante en la Fase 5 cuando exista users.email.
* Password de producción sale de ENV, nunca hardcodeada en database.yml.

## 12-13. Mantenibilidad y compatibilidad futura

docs/conventions/database.md responde de antemano las preguntas que un desarrollador nuevo (o tú mismo en 8 meses) se haría al crear una tabla: ¿bigint o UUID?, ¿soft delete?, ¿JSONB o columnas?. La convención de índices concurrentes ya queda escrita antes de que exista una tabla grande, así que en la Fase 12 (Usuarios) o más adelante no hay que inventarla sobre la marcha.