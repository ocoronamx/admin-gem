# Convenciones de testing — admin-gem

## Qué sí se prueba
- Autorización y autoprotección (`spec/policies/`) — es donde un bug es
  silencioso y grave (nadie nota que le faltó un `authorize`).
- Comportamiento de seguridad cross-cutting: sesión cortada al desactivar un
  usuario, mensajes de login que no distinguen cuenta inexistente de
  desactivada, diffs de auditoría que nunca exponen `password_digest`.
- Validaciones y normalización de modelos con lógica real (formato, unicidad,
  scopes de filtro).
- El camino feliz + el camino denegado de cada request protegido por Pundit.

## Qué no se prueba (a propósito, no por omisión)
- Helpers que son un lookup estático sin lógica de decisión (`IconsHelper`).
  Se verifican a ojo en `/styleguide`, que ya los inventaria a todos.
- `AdminFormBuilder` en aislamiento — se prueba indirecto, a través de los
  request specs de cualquier vista que use un formulario real.
- Modelos de join puro (`RolePermission`, `Session`) — se ejercitan a través
  del modelo que los usa (`role.permissions <<`, `user.sessions`).
- View specs aislados — si ya existe un request spec para esa ruta, no se
  duplica con un view spec del mismo template.

## Regla para decidir si un pending se completa o se borra
Un pending generado por scaffold se borra si no hay lógica de decisión que
probar (branches, mapeos, formato). Se completa si la hay. Nunca queda
pending "por las dudas" — o se prueba, o se borra con esta lógica documentada.

## Autenticación en request specs
`sign_in(user)` (en `spec/support/authentication_helpers.rb`, incluido
automáticamente en specs `type: :request`) — no reinventar esto por archivo.

## Factories
Faker para datos donde el valor específico no importa (`Faker::Internet.email`).
Cuando el valor sí importa para el test (un permiso puntual, un rol con nombre
específico), se sigue pasando explícito: `create(:role, name: "Editor", key: "editor")`.
