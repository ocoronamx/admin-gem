# Convenciones de formularios — admin-gem

## Form builder por defecto
Todo `form_with` usa `AdminFormBuilder` automáticamente (`config.action_view.default_form_builder`
en `config/application.rb`) — no hace falta pasar `builder:`.

## Campos disponibles
`text_field`, `email_field`, `password_field`, `number_field`, `date_field`, `text_area`,
`select`, `tom_select`, `check_box`. Todos aceptan `label:` y `hint:` además de sus
opciones normales de Rails.

```erb
<%= form.text_field :name, label: "Nombre", hint: "Como aparece en tu perfil." %>
```

Sin `label:`, se usa `object.class.human_attribute_name(atributo)` humanizado. Los
errores del modelo se muestran solos en el mismo espacio que un `hint:` — nunca hace
falta chequear `object.errors.any?` a mano en la vista.

## select vs tom_select
`select` es el nativo de Rails, estilizado. `tom_select` es el mismo `<select>` con
búsqueda/tags/multi-selección vía Tom Select — úsalo con listas largas o selección
múltiple. Es progresivo: sin JS, sigue siendo un `<select>` normal.

## Inputs de fecha
`date_field` renderiza `<input type="date">` nativo — sin JS ni librería de calendario
(Flatpickr está abandonado, ver ADR §3.4). Para un caso puntual que necesite más
(rango visual, calendario inline), existe el seam `data-controller="datepicker"`
(hoy vacío a propósito) para enchufar una librería concreta sin tocar el resto.

## Validación
Los campos llevan la clase `validator` de DaisyUI v5: colorean el input según las
reglas HTML5 nativas (`required`, `pattern`, `minlength`, `type="email"`) sin JS.
`validator-hint` muestra el error del servidor cuando existe, o el `hint:` estático
si no hay error — nunca los dos a la vez.

## Cómo añadir un campo que el builder no tiene
Seguí el mismo patrón que los demás: `def radio_button(attribute, tag_value, options = {}); field(attribute, options) { |opts| super(attribute, tag_value, opts) }; end`.
```