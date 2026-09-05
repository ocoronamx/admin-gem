Tiene sentido que lo hayas notado — es un bug real de mi CSS de Setup 9, no algo que hicieras vos. Ya sé cuál es la causa más probable: nunca declaré `position: absolute` en `.ts-dropdown` (ni `position: relative` en `.ts-wrapper`, que es lo que necesita para posicionarse relativo al control). Sin eso, el dropdown de Tom Select no flota como overlay — queda en el flujo normal del documento, siempre visible, mostrando las 5 opciones como si estuvieran ahí permanentemente.

## Fix (de paso, antes de Setup 15)

**app/assets/tailwind/application.css** — agrega `position: relative` al wrapper y reemplaza el bloque de `.ts-dropdown`:

```css
.ts-wrapper {
  position: relative;
}

.ts-dropdown {
  position: absolute;
  left: 0;
  right: 0;
  margin-top: 0.25rem;
  background-color: var(--color-base-100);
  border: var(--border, 1px) solid var(--color-base-300);
  border-radius: var(--radius-field);
  box-shadow: 0 4px 12px rgb(0 0 0 / 0.1);
  overflow: hidden;
  z-index: 20;
}
```

Probá `/styleguide` de nuevo después de esto — el campo de Tecnologías debería arrancar vacío, y el dropdown solo debería aparecer al hacer click, flotando sobre el resto del formulario. Si sigue sin comportarse bien (por ejemplo, si el dropdown aparece pero en el lugar equivocado, o si el problema era otra cosa), avisame — no tengo forma de verlo renderizado desde acá, así que esto es mi mejor diagnóstico, no una certeza confirmada visualmente.

---

Ahora, Setup 15. Reviso el estado real de los specs antes de escribirlo, porque acá el trabajo no es "elegir RSpec" (ya está desde el inicio) sino decidir qué hacer con cada pending que se fue acumulando, y dejar por escrito el criterio que ya venías siguiendo implícitamente.