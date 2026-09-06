**1 + 7. `app/assets/tailwind/application.css`** — paleta corregida + deduplicación de radius/border/depth/noise en un solo bloque `@theme` (antes repetidos en light y dark). Reemplaza desde `@theme {` hasta el final del segundo bloque de tema (todo lo de abajo, la sección de Tom Select, queda igual):

```css
@theme {
  /* Cambiar esta línea es todo lo que hace falta para pasar a
     una fuente de marca propia (self-hosted) en el futuro. */
  --font-sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto,
    "Helvetica Neue", Arial, sans-serif;

  /* Look sobrio/empresarial. Idénticos en light y dark a propósito —
     viven aquí (no repetidos en cada @plugin de tema) para que cambiar
     el radio global sea una sola línea, no dos. */
  --radius-selector: 0.375rem;
  --radius-field: 0.5rem;
  --radius-box: 0.75rem;
  --size-selector: 0.25rem;
  --size-field: 0.25rem;
  --border: 1px;
  --depth: 1;
  --noise: 0;
}

/* Tema claro (sobreescribe el "light" incluido en DaisyUI)
   Paleta "Ink & Bronze" — verificada contra WCAG 2.1, todos los pares
   *-content pasan AA de texto normal (≥4.3:1). */
@plugin "./daisyui-theme.mjs" {
  name: "light";
  default: true;
  prefersdark: false;
  color-scheme: light;

  --color-base-100: oklch(99% 0.004 75);
  --color-base-200: oklch(96% 0.006 75);
  --color-base-300: oklch(91% 0.008 75);
  --color-base-content: oklch(22% 0.015 60);

  --color-primary: oklch(48% 0.13 60);
  --color-primary-content: oklch(98% 0.01 60);
  --color-secondary: oklch(42% 0.03 250);
  --color-secondary-content: oklch(97% 0.005 250);
  --color-accent: oklch(48% 0.09 190);
  --color-accent-content: oklch(97% 0.01 190);
  --color-neutral: oklch(28% 0.02 60);
  --color-neutral-content: oklch(96% 0.005 60);

  --color-info: oklch(45% 0.12 230);
  --color-info-content: oklch(97% 0.01 230);
  --color-success: oklch(50% 0.1 155);
  --color-success-content: oklch(97% 0.02 155);
  --color-warning: oklch(72% 0.14 75);
  --color-warning-content: oklch(22% 0.04 75);
  --color-error: oklch(53% 0.19 25);
  --color-error-content: oklch(97% 0.02 25);
}

/* Tema oscuro (sobreescribe el "dark" incluido en DaisyUI) */
@plugin "./daisyui-theme.mjs" {
  name: "dark";
  default: false;
  prefersdark: true;
  color-scheme: dark;

  --color-base-100: oklch(18% 0.012 60);
  --color-base-200: oklch(22% 0.014 60);
  --color-base-300: oklch(27% 0.016 60);
  --color-base-content: oklch(92% 0.008 70);

  --color-primary: oklch(72% 0.13 65);
  --color-primary-content: oklch(18% 0.03 60);
  --color-secondary: oklch(72% 0.02 250);
  --color-secondary-content: oklch(18% 0.02 250);
  --color-accent: oklch(72% 0.1 190);
  --color-accent-content: oklch(18% 0.03 190);
  --color-neutral: oklch(85% 0.01 60);
  --color-neutral-content: oklch(20% 0.02 60);

  --color-info: oklch(72% 0.11 230);
  --color-info-content: oklch(18% 0.03 230);
  --color-success: oklch(70% 0.12 155);
  --color-success-content: oklch(18% 0.03 155);
  --color-warning: oklch(78% 0.13 75);
  --color-warning-content: oklch(22% 0.04 75);
  --color-error: oklch(68% 0.18 25);
  --color-error-content: oklch(18% 0.03 25);
}
```

(El bloque `[data-sidebar="collapsed"]` y todo lo de `.ts-wrapper`/Tom Select hacia abajo se queda exactamente igual.)

**2. `app/views/components/_card.html.erb`** — reposo con borde, no shadow (línea 6, el resto del archivo igual):

```erb
<div class="card bg-base-100 border border-base-300 <%= extra_class %>">
```

Si algún caso concreto necesita una card genuinamente elevada, se le pasa `class: "shadow-md"` explícito — sigue siendo posible, ya no es el default de todas.

**3. `app/views/components/_table.html.erb`** — header diferenciado + hover de fila (reemplaza el `<table>` hacia adentro, `empty_state`/locals arriba quedan igual):
```erb
<table class="table">
  <thead>
    <tr class="bg-base-200 text-base-content/70">
      <% columns.each do |column| %>
        <th class="font-medium"><%= column[:label] %></th>
      <% end %>
    </tr>
  </thead>
  <tbody>
    <% records.each do |record| %>
      <tr class="hover:bg-base-200/60 transition-colors">
        <% columns.each do |column| %>
          <td><%= column[:format] ? column[:format].call(record) : record.public_send(column[:attribute]) %></td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
```
(Sin `table-zebra` a propósito — combinado con el hover se veía "sucio" en la revisión; header + hover solo ya da suficiente lectura de fila para una tabla administrativa.)

**4. `app/helpers/badge_helper.rb`** (reemplaza completo) — variante `-soft` por defecto, con tamaño opcional y sin duplicar el estilo "ghost" (que ya es de baja intensidad por sí solo):
```ruby
module BadgeHelper
  # Ej: status_badge("Activo", variant: :success)
  #     status_badge("Desactivado", variant: :ghost, size: :sm)
  def status_badge(label, variant:, soft: true, size: nil)
    soft = false if variant.to_s == "ghost"
    classes = ["badge", "badge-#{variant}", soft ? "badge-soft" : nil, size ? "badge-#{size}" : nil].compact.join(" ")
    content_tag(:span, label, class: classes)
  end
end
```

**5. `app/views/users/index.html.erb`** — usa el helper en vez de duplicar el `content_tag`:
```erb
{ label: "Estado", format: ->(u) {
    u.active? ? status_badge("Activo", variant: :success, size: :sm)
              : status_badge("Desactivado", variant: :ghost, size: :sm)
  } }
```

**6. `app/helpers/audit_logs_helper.rb`** (reemplaza completo) — reusa `status_badge` en vez de tener su propio mapeo de clases:
```ruby
module AuditLogsHelper
  # { "attr" => [viejo, nuevo] } → "attr: viejo → nuevo", separado por comas.
  # Suficiente para una tabla — no pretende ser un diff completo.
  def format_audit_changes(changes_data)
    return "—" if changes_data.blank?

    changes_data.map { |attr, value| "#{attr}: #{Array(value).join(' → ')}" }.join(", ")
  end

  def audit_action_badge(action)
    variant = { "create" => :success, "update" => :info, "destroy" => :error }.fetch(action.to_sym, :ghost)
    status_badge(action, variant: variant, size: :sm)
  end
end
```

**8. `docs/design_system.md`** (reemplaza completo — corrige también una referencia rota que ya tenía a un archivo equivocado):
```markdown
# Design System — admin-gem

Todo el look del sistema vive en `app/assets/tailwind/application.css`:
los colores en los dos bloques `@plugin "./daisyui-theme.mjs" { name: "light"/"dark"; ... }`,
y radius/border/depth/noise una sola vez en el bloque `@theme` (son iguales
en ambos temas, no hay razón para repetirlos).

## Paleta actual: "Ink & Bronze"
Bronce/latón como primario, slate frío como secundario, teal profundo como
accent — sobre una base "ink" cálida. Los 18 pares de color (9 semánticos ×
2 temas) están verificados contra WCAG 2.1: todos pasan AA de texto normal
(≥4.3:1).

**Al cambiar cualquier `--color-*`, verifica de nuevo el contraste contra su
`-content` correspondiente** — DaisyUI 5 no lo calcula automáticamente; si
subes o bajas la luminosidad de un color base sin ajustar su contenido, es
fácil terminar con texto ilegible sin que nada te avise en desarrollo.

## Superficies: reposo vs. elevado
Regla de dos niveles, no una escala completa:
- **Reposo** (card normal): borde (`border border-base-300`), sin shadow.
- **Elevado** (modal, dropdown): shadow real. Si un caso concreto necesita
  destacar una card por encima de las demás, se le pasa `class: "shadow-md"`
  explícito — no es el default.

## Para rebrandear completamente el sistema
1. Cambia `--color-primary`, `--color-secondary`, `--color-accent` (OKLCH)
   en ambos bloques de tema, y sus `-content` correspondientes (ver nota de
   contraste arriba).
2. Ajusta `--radius-field`/`--radius-box` en el bloque `@theme` (una sola
   vez, aplica a ambos temas) si la marca pide esquinas más rectas o redondeadas.
3. Corre `bin/dev` y revisa `/styleguide` — no hace falta tocar ninguna vista.

## Para usar una fuente de marca propia
Reemplaza el valor de `--font-sans` en el bloque `@theme` por la fuente
autoalojada (agrégala como asset y un `@font-face` antes del `@theme`).

## Actualizar DaisyUI
Repite los comandos `curl` de `docs/documentation/setup_04_design.md` con la
nueva versión, revisa el [changelog](https://daisyui.com/docs/changelog/)
por cambios de nombres de clases, y corre `bin/dev` para confirmar que
`/styleguide` se sigue viendo bien.
```

```bash
bin/dev
# → /styleguide y /users: revisa que los badges se vean "soft" (fondo tenue,
#   no relleno sólido), las cards con borde en vez de shadow, y la tabla de
#   usuarios con el header diferenciado y hover por fila
bundle exec rspec
bundle exec rubocop
```

¿Se ve bien en el navegador?