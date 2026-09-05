# Convenciones de auditoría — admin-gem

## Cómo hacer un modelo auditable
`include Auditable` — registra automáticamente create/update/destroy con el
diff de `ActiveModel::Dirty`. Si el modelo tiene columnas sensibles, excluilas:

```ruby
class User < ApplicationRecord
  include Auditable
  audit_excludes :password_digest
end
```

`created_at`/`updated_at` ya están excluidas por defecto — son ruido, no una
decisión de negocio.

## Qué queda registrado
`AuditLog`: quién (`user`, nil si fue el sistema — seeds, jobs), qué pasó
(`action`: create/update/destroy), sobre qué (`resource` polimórfico),
el diff (`changes_data`, jsonb), IP y user-agent (vía `Current.request`,
seteado en `ApplicationController#set_current_request`).

## Solo `.view`, nunca `.manage`
Un audit log no se edita ni se borra desde el panel — el permiso `manage`
no tendría significado acá. Es la única excepción a la convención
`<recurso>.view`/`<recurso>.manage` de `docs/conventions/authorization.md`.

## Qué no cubre esta fase (a propósito)
- Auditar los join models (`UserRole`, `RolePermission`) — se agrega si aparece
  un caso real de "quién le dio tal permiso a tal rol".
- Restauración point-in-time — si hace falta compliance más pesado, el ADR
  ya anota migrar a la gema `audited` como mejora incremental, no como base.
