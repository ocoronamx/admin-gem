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
No hay mecanismo genérico — cada módulo que necesite "desactivar sin borrar" añade
su propia columna explícita y sus propios scopes. Referencia real: Usuarios (Setup 13):
- Columna `deactivated_at:datetime`, nil = activo.
- `scope :active` / `scope :deactivated` en el modelo, método `active?`.
- La sesión de un usuario desactivado se corta en el próximo request, no solo
  se bloquea el próximo login (`Authentication#find_session_by_cookie`).
- Nunca un mensaje que distinga "no existe" de "está desactivado" en el login.

## Migraciones
- Una migración = un cambio conceptual. No mezclar cambio de esquema con
  backfill de datos en la misma migración.
- Todo `change` debe ser reversible; si no lo es, se implementan `up`/`down`
  explícitos con un comentario explicando por qué.