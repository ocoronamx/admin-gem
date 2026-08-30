# Convenciones de autorización — admin-gem

## Modelo de datos
`User belongs_to :role`. `Role has_many :permissions` a través de `role_permissions`.
Los permisos son texto libre, formato `recurso.nivel`.

## Los dos niveles de permiso
- `<recurso>.view` — listar y ver (`index?`, `show?`)
- `<recurso>.manage` — crear, editar, eliminar (`create?`, `update?`, `destroy?`)

Sin granularidad extra a propósito. Si un módulo concreto la necesita
(ej. `reports.export`), ese módulo agrega su propio nivel — no se toca la convención global.

## Cómo añadir autorización a un módulo nuevo (ej. Usuarios, Setup 13)
1. `class UserPolicy < ApplicationPolicy; class Scope < ApplicationPolicy::Scope; end; end`
   — declara `Scope` explícitamente **siempre**, aunque no le agregues nada.
   Es la recomendación oficial de Pundit: en versiones anteriores a la 2.3.1 la
   resolución implícita de la constante `Scope` anidada era ambigua.
2. El nombre de la policy define el recurso solo: `UserPolicy` → `users`. Nada que registrar.
3. Siembra los permisos que falten (`users.view`, `users.manage`) y asígnalos a los roles.
4. En el controlador: `authorize @user` (o `authorize User` en acciones de colección)
   y `policy_scope(User)` en `index`. `ApplicationController` falla si falta alguno.

## Gestión de roles/permisos desde la UI
No existe todavía — por ahora se siembran en `db/seeds.rb`. Candidato natural
para el módulo "Configuración" cuando exista.