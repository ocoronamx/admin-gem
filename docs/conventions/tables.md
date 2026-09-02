# Convenciones de tablas y filtros — admin-gem

## Componente de tabla
`render "components/table", columns: [...], records: @algo, empty_title: "..."`.
Cada columna es `{ label:, attribute: }` (llama `record.public_send(attribute)`) o
`{ label:, format: ->(record) { ... } }` para contenido calculado. Si `records` está
vacío, renderiza `components/empty_state` en vez de una tabla vacía.

## Paginación (Pagy 43)
`include Pagy::Method` ya está en `ApplicationController`.

```ruby
@pagy, @roles = pagy(:offset, apply_filters(policy_scope(Role)).order(:name))
```

```erb
<%== @pagy.info_tag %>
<%== @pagy.series_nav(
  nav_extra: 'class="join"', link_extra: 'class="join-item btn btn-sm"',
  active_link_extra: 'class="join-item btn btn-sm btn-active"'
) %>
```

`<%==` (doble `=`), no `<%=` — Pagy no marca sus strings como `html_safe` a propósito
(es agnóstico de Rails). Las clases `join`/`btn` son de DaisyUI, inyectadas vía las
opciones `*_extra` de Pagy — no hace falta CSS custom para la paginación.

## Filtros: lista blanca de scopes, nunca Ransack
Decisión del ADR (advisories de seguridad de Ransack por exposición de atributos no
previstos). El flujo:

1. El modelo define scopes explícitos y seguros: `scope :by_name, ->(v) { where("name ILIKE ?", "%#{sanitize_sql_like(v)}%") }`.
2. El controlador declara la lista blanca: `filterable_by :by_name, :by_key`.
3. `apply_filters(scope)` solo invoca los scopes declarados — cualquier otra clave en
   `params[:q]` se descarta antes de tocar la base de datos.

Nunca agregues a `filterable_by` un scope que no valide/escape su propio input.

## Cómo se ve en un controlador nuevo (ej. Setup 13, Usuarios)
```ruby
class UsersController < ApplicationController
  filterable_by :by_email

  def index
    @pagy, @users = pagy(:offset, apply_filters(policy_scope(User)).order(:email_address))
  end
end
```