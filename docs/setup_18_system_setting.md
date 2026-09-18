# Pasos de configuración de sistema

1. **Fundación visual** — los dos temas base (`classic` e `ink_bronze`) coexistiendo en CSS, cero cambio visible todavía.
2. **Capa de datos** — `SystemSetting`, Active Storage, policy, permisos, seeds. Existe pero nada lo usa todavía.
3. **El cambio real** — controlador, rutas, vista de configuración, y ahí sí se apaga la cookie personal y se prende el sistema nuevo.
4. **Specs + limpieza** — tests del modelo/policy/controller, y borrar lo que quedó muerto (`theme_toggle_controller.js`, la cookie).


## Paso 1 — Dos temas base, sin romper nada

**Decisión**: renombro lo que ya existe en `main` (`"light"`/`"dark"`) a `classic-light`/`classic-dark` — es exactamente la misma paleta, solo con nombre nuevo — y agrego `ink_bronze-light`/`ink_bronze-dark` (la paleta de `feat/theme`) **dormida**: existe en la CSS pero nada la selecciona todavía. Cero cambio visible al terminar este paso; se verifica a mano en devtools.

**app/assets/tailwind/application.css** — reemplaza los dos bloques `@plugin` actuales por estos cuatro (el bloque `@theme` de arriba, con `--radius-*`/`--border`/etc., queda exactamente igual):

```css
@plugin "./daisyui-theme.mjs" {
  name: "classic-light";
  default: true;
  prefersdark: false;
  color-scheme: light;

  --color-base-100: oklch(100% 0 0);
  --color-base-200: oklch(97% 0.002 247);
  --color-base-300: oklch(92% 0.004 247);
  --color-base-content: oklch(21% 0.006 285);

  --color-primary: oklch(45% 0.15 264);
  --color-primary-content: oklch(97% 0.01 264);
  --color-secondary: oklch(55% 0.04 255);
  --color-secondary-content: oklch(98% 0.01 255);
  --color-accent: oklch(70% 0.14 200);
  --color-accent-content: oklch(20% 0.05 200);
  --color-neutral: oklch(30% 0.01 260);
  --color-neutral-content: oklch(96% 0.005 260);

  --color-info: oklch(65% 0.15 235);
  --color-info-content: oklch(98% 0.01 235);
  --color-success: oklch(62% 0.15 155);
  --color-success-content: oklch(98% 0.02 155);
  --color-warning: oklch(80% 0.15 85);
  --color-warning-content: oklch(25% 0.05 85);
  --color-error: oklch(60% 0.22 25);
  --color-error-content: oklch(98% 0.02 25);
}

@plugin "./daisyui-theme.mjs" {
  name: "classic-dark";
  default: false;
  prefersdark: false;
  color-scheme: dark;

  --color-base-100: oklch(19% 0.006 285);
  --color-base-200: oklch(23% 0.006 285);
  --color-base-300: oklch(28% 0.007 285);
  --color-base-content: oklch(93% 0.004 260);

  --color-primary: oklch(70% 0.14 264);
  --color-primary-content: oklch(20% 0.05 264);
  --color-secondary: oklch(70% 0.03 255);
  --color-secondary-content: oklch(20% 0.02 255);
  --color-accent: oklch(75% 0.13 200);
  --color-accent-content: oklch(20% 0.05 200);
  --color-neutral: oklch(85% 0.005 260);
  --color-neutral-content: oklch(20% 0.01 260);

  --color-info: oklch(72% 0.14 235);
  --color-info-content: oklch(20% 0.05 235);
  --color-success: oklch(70% 0.15 155);
  --color-success-content: oklch(20% 0.05 155);
  --color-warning: oklch(80% 0.15 85);
  --color-warning-content: oklch(25% 0.05 85);
  --color-error: oklch(68% 0.2 25);
  --color-error-content: oklch(20% 0.05 25);
}

/* Dormido por ahora — nada lo selecciona hasta el Paso 3. Paleta cálida
   ("Ink & Bronze"): bronce/latón primario, slate frío secundario, teal
   profundo de acento. Verificado contra WCAG 2.1 (AA, ≥4.3:1). */
@plugin "./daisyui-theme.mjs" {
  name: "ink_bronze-light";
  default: false;
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

@plugin "./daisyui-theme.mjs" {
  name: "ink_bronze-dark";
  default: false;
  prefersdark: false;
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

Nota: le quité `prefersdark: true` al que lo tenía en `feat/theme` — con **dos** temas de fondo oscuro coexistiendo (`classic-dark`, y ahora `ink_bronze-dark` dormido), dejar `prefersdark` en cualquiera de los dos sería arbitrario hasta que el Paso 3 decida esto de verdad vía `SystemSetting`. Por ahora todo lo maneja `classic-*` explícito, no la preferencia del sistema operativo.

**app/controllers/application_controller.rb** — cambia solo `set_theme` (transición: sigue leyendo la cookie personal, pero ahora compone el nombre completo del tema; esto lo reemplaza el Paso 3):

```ruby
  # TRANSICIÓN (Paso 1 de 4 hacia SystemSetting): sigue leyendo la cookie
  # personal, pero ahora compone el nombre completo del tema ("classic-light",
  # etc.) — hardcodeado a "classic" hasta que el Paso 3 lo reemplace por la
  # selección real del sistema.
  #
  # @return [String] El tema activo compuesto, ej. "classic-dark".
  def set_theme
    mode = %w[light dark].include?(cookies[:theme]) ? cookies[:theme] : "light"
    @current_theme = "classic-#{mode}"
  end
```

**app/javascript/controllers/theme_toggle_controller.js** — mismo criterio, un solo `data-theme` compuesto:

```javascript
import { Controller } from "@hotwired/stimulus"

// TRANSICIÓN (Paso 1 de 4): sigue siendo la cookie personal, "classic-"
// hardcodeado hasta el Paso 3.
export default class extends Controller {
  persist(event) {
    const theme = event.target.checked ? "dark" : "light"
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    document.documentElement.setAttribute("data-theme", `classic-${theme}`)

    window.dispatchEvent(new CustomEvent("theme:change"))
  }
}
```

## Validaciones

```bash
bin/dev
# → todo se ve exactamente igual que antes — el toggle del header sigue
#   alternando claro/oscuro sin ningún cambio visible

# En devtools console, para confirmar que ink_bronze está bien formado
# aunque todavía nadie lo seleccione:
document.documentElement.setAttribute("data-theme", "ink_bronze-light")
# → /styleguide debería verse con la paleta cálida (bronce/latón). Volvé a
#   "classic-light" (o recargá) para dejarlo como estaba.

bundle exec rubocop
```

Confirmame que esto corre bien y sin diferencias visuales, y seguimos con el Paso 2 (el modelo `SystemSetting`, Active Storage, policy y seeds — todavía sin conectar a nada que se vea).

# TODO
