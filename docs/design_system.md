# Design System — admin-gem

Todo el look del sistema vive en `app/assets/tailwind/application.css`,
dentro de los dos bloques `@plugin "./daisyui-theme.mjs" { name: "light"/"dark"; ... }`.

## Para rebrandear completamente el sistema
1. Cambia los valores `--color-primary`, `--color-secondary`, `--color-accent`
   (formato OKLCH recomendado) en ambos bloques de tema.
2. Ajusta `--radius-field`/`--radius-box` si la marca pide esquinas más
   rectas o más redondeadas.
3. Corre `bin/dev` y revisa `/styleguide` — no hace falta tocar ninguna vista.

## Para usar una fuente de marca propia
Reemplaza el valor de `--font-sans` en el bloque `@theme` por la fuente
autoalojada (agrégala como asset y un `@font-face` antes del `@theme`).

## Actualizar DaisyUI
Repite los comandos `curl` de documentation/setup_3_database.yml con la nueva versión, revisa el
[changelog](https://daisyui.com/docs/changelog/) por cambios de nombres de
clases, y corre `bin/dev` para confirmar que `/styleguide` se sigue viendo bien.