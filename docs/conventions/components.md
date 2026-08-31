# Convenciones de componentes — admin-gem

| Necesitas | Patrón | Ejemplo |
|---|---|---|
| Un texto/valor simple como parámetro | Partial con locals | `render "components/button", text: "Guardar", variant: :primary` |
| Contenido HTML libre adentro | Partial como layout (yield) | `render(layout: "components/card", locals: { title: "..." }) { ... }` |
| Una decisión de una línea sin marcado propio | Helper | `status_badge("Activo", variant: :success)` |
| Interactividad en el navegador | Stimulus controller | `data-controller="modal"` |

## Componentes disponibles
- `components/_button`, `components/_card`, `components/_alert`, `components/_empty_state`, `components/_modal`
- Confirmación destructiva: `data: { turbo_method: :delete, turbo_confirm: "..." }` en cualquier link/botón

## Deliberadamente no incluidos todavía
Tabs, Toast, Dropdown genérico — se extraen cuando aparezca un **segundo** caso de uso
real. Antes de eso, generalizar es adivinar la forma que van a necesitar.
