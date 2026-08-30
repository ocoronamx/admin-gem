# Prompt — Arquitectura y construcción de Boilerplate Administrativo Premium con Ruby on Rails

Actúa como un **Software Architect / Staff Engineer / Senior Ruby on Rails Engineer** con amplia experiencia construyendo plataformas administrativas empresariales de larga vida útil.

Quiero que diseñes y construyas **paso a paso**, desde cero, un **boilerplate/template administrativo profesional, moderno, premium, seguro, escalable, mantenible y preparado para evolucionar durante muchos años**.

El objetivo NO es crear una aplicación administrativa específica para un negocio, sino construir una **base reutilizable** sobre la cual posteriormente puedan desarrollarse múltiples sistemas administrativos, empresariales, institucionales o internos.

---

# 1. Objetivo general

Construir un boilerplate administrativo que tenga como prioridades, en este orden:

1. Seguridad.
2. Calidad arquitectónica.
3. Mantenibilidad.
4. Escalabilidad.
5. Experiencia de desarrollo (DX).
6. Experiencia de usuario (UX).
7. Rendimiento.
8. Consistencia visual.
9. Facilidad para incorporar nuevos módulos.
10. Larga vida útil y facilidad de actualización tecnológica.

Debe evitarse diseñar pensando únicamente en que "funcione ahora".

La arquitectura debe considerar:

* Evolución del proyecto durante años.
* Actualizaciones futuras de Ruby y Rails.
* Actualizaciones de dependencias.
* Cambios de diseño.
* Crecimiento de usuarios.
* Crecimiento de datos.
* Incremento de módulos.
* Nuevos desarrolladores incorporándose al proyecto.
* Diferentes niveles de permisos.
* Auditoría y trazabilidad.
* Internacionalización.
* Accesibilidad.
* Seguridad.
* Testing.
* Observabilidad.
* CI/CD.
* Posible extracción futura de componentes o servicios cuando realmente sea necesario.

No quiero una arquitectura innecesariamente compleja ni "enterprise architecture" artificial.

**Prefiere simplicidad, convenciones de Rails y modularidad pragmática.**

---

# 2. Stack tecnológico base

Utiliza como base:

* Ruby
* Ruby on Rails
* PostgreSQL
* Tailwind CSS
* DaisyUI
* Tom Select
* ApexCharts
* Flatpickr
* Pagy
* Pundit

Tienes **moderada libertad para mejorar o sustituir una tecnología** cuando exista una alternativa claramente superior.

Sin embargo:

* No sustituyas tecnologías simplemente por preferencia personal.
* Justifica cualquier cambio.
* Prioriza estabilidad, mantenimiento, comunidad, documentación y compatibilidad futura.
* Evita dependencias innecesarias.
* Evita librerías abandonadas o con mantenimiento dudoso.
* Evita incorporar frameworks adicionales cuando Rails ya resuelva correctamente el problema.

Si consideras que alguna tecnología debe complementarse con otra, puedes hacerlo, pero debes explicar claramente por qué.

---

# 3. Principios arquitectónicos

Diseña el proyecto siguiendo principios como:

* Convention over Configuration.
* SOLID cuando aporte valor.
* DRY sin caer en abstracciones excesivas.
* KISS.
* Separation of Concerns.
* Single Responsibility.
* Secure by Default.
* Least Privilege.
* Fail Secure.
* Explicit over Magic cuando mejore la mantenibilidad.
* Código legible antes que código excesivamente sofisticado.
* Preferir soluciones nativas de Rails.
* Evitar premature optimization.
* Evitar premature abstraction.
* Modularidad.
* Evolución incremental.
* Backward compatibility cuando sea razonable.

No quiero:

* Sobreingeniería.
* Microservicios innecesarios.
* Service Objects para absolutamente todo.
* Repositorios innecesarios.
* Patrones de diseño introducidos únicamente para "verse profesionales".
* Dependencias que resuelvan problemas triviales.
* Código generado sin explicar su propósito.

---

# 4. Filosofía de construcción

NO generes todo el proyecto de una sola vez.

Quiero que trabajes como si estuvieras liderando técnicamente el desarrollo de un proyecto real.

Divide el trabajo en fases.

Para cada fase:

1. Explica el objetivo.
2. Explica las decisiones arquitectónicas.
3. Explica las alternativas consideradas.
4. Indica qué problemas estamos previniendo.
5. Muestra los comandos necesarios.
6. Crea/modifica los archivos necesarios.
7. Explica cada archivo importante.
8. Incluye código completo cuando sea necesario.
9. Verifica consistencia entre archivos.
10. Propón pruebas o validaciones.
11. Revisa seguridad.
12. Revisa mantenibilidad.
13. Revisa compatibilidad futura.
14. Espera mi confirmación antes de avanzar a la siguiente fase.

**No avances automáticamente a la siguiente fase.**

---

# 5. Antes de comenzar

Antes de escribir código, realiza una propuesta arquitectónica inicial.

Incluye:

### 5.1 Versiones recomendadas

Determina versiones recomendadas y estables de:

* Ruby
* Rails
* PostgreSQL
* Node.js, si realmente es necesario
* Tailwind
* DaisyUI
* Pagy
* Pundit
* Tom Select
* ApexCharts
* Flatpickr

Prioriza versiones con buen soporte y vida útil razonable.

Si existe una versión nueva pero consideras que todavía no es conveniente para un boilerplate de larga vida, explica por qué.

---

### 5.2 Arquitectura general

Propón la arquitectura de:

```text
Browser
   ↓
Rails
   ├── Controllers
   ├── Policies
   ├── Models
   ├── Services (solo cuando sean necesarios)
   ├── Queries (solo cuando aporten valor)
   ├── Jobs
   ├── Mailers
   └── Views
        ↓
   PostgreSQL
```

Puedes modificar esta estructura si existe una mejor alternativa.

---

### 5.3 Estructura del proyecto

Define una estructura de directorios clara y escalable.

Debe ser fácil incorporar módulos como:

```text
Dashboard
Usuarios
Roles
Permisos
Catálogos
Reportes
Auditoría
Configuración
Notificaciones
```

sin convertir el proyecto en un monolito desorganizado.

---

# 6. Diseño visual

El sistema debe tener una estética:

* Premium.
* Profesional.
* Moderna.
* Sobria.
* Empresarial.
* Limpia.
* Consistente.
* Responsive.
* Accesible.
* Orientada a aplicaciones administrativas.

No quiero que parezca un CRUD genérico generado automáticamente.

Define un **Design System** inicial.

Debe contemplar:

### Layout

* Sidebar.
* Header/Navbar.
* Breadcrumbs.
* Main content.
* Footer cuando sea necesario.
* Mobile navigation.
* Sidebar colapsable.

### Componentes

Crear componentes visuales reutilizables para:

* Buttons.
* Links.
* Cards.
* Tables.
* Forms.
* Inputs.
* Selects.
* Date pickers.
* Badges.
* Alerts.
* Notifications.
* Modals.
* Dropdowns.
* Tabs.
* Breadcrumbs.
* Pagination.
* Empty states.
* Loading states.
* Error states.
* Confirmation dialogs.

Utiliza DaisyUI y Tailwind de manera consistente.

No disperses estilos arbitrarios por todas las vistas.

---

# 7. Sistema de diseño

Define tokens para:

* Colores.
* Tipografía.
* Spacing.
* Border radius.
* Shadows.
* Transitions.
* Focus states.
* Estados de componentes.

Debe existir una estrategia clara para poder cambiar posteriormente el branding completo del sistema sin modificar cientos de archivos.

Considera desde el inicio:

* Light mode.
* Dark mode.
* Estados hover.
* Focus.
* Disabled.
* Error.
* Success.
* Warning.
* Info.

---

# 8. Autenticación y autorización

Diseña una solución robusta para:

* Login.
* Logout.
* Password recovery.
* Password security.
* Session management.
* Account lockout cuando corresponda.
* Protección contra ataques comunes.
* Autorización mediante Pundit.

Define claramente la diferencia entre:

**Authentication**

y

**Authorization**

La autorización debe diseñarse pensando en:

```text
User
  ↓
Roles
  ↓
Permissions
  ↓
Resources / Actions
```

Evita implementar permisos mediante condiciones dispersas como:

```ruby
if current_user.admin?
```

por toda la aplicación.

Utiliza Pundit correctamente y diseña una estrategia que pueda crecer.

---

# 9. Seguridad

Implementa Security by Default.

Analiza como mínimo:

* CSRF.
* XSS.
* SQL Injection.
* Mass Assignment.
* Session fixation.
* Brute force.
* Password security.
* Authorization bypass.
* IDOR.
* Parameter tampering.
* Unsafe redirects.
* File uploads.
* Malicious input.
* Secure headers.
* Cookies.
* Content Security Policy.
* Secrets management.
* Credentials.
* Logs.
* Sensitive information exposure.
* Error pages.
* Dependency vulnerabilities.

Considera OWASP Top 10.

No te limites a decir "Rails ya lo protege".

Explica qué proporciona Rails y qué debemos configurar nosotros.

---

# 10. PostgreSQL

Diseña la base de datos pensando en crecimiento.

Define:

* Naming conventions.
* Primary keys.
* Foreign keys.
* Indexes.
* Unique constraints.
* Check constraints.
* Nullability.
* Timestamps.
* Soft delete únicamente si realmente se justifica.
* Auditing.
* JSONB cuando sea apropiado.
* UUID vs bigint.

Explica cuándo utilizar cada estrategia.

Evita utilizar JSONB como sustituto de un diseño relacional correcto.

---

# 11. Migraciones

Las migraciones deben ser:

* Incrementales.
* Reversibles cuando sea razonable.
* Seguras para producción.
* Claras.
* Pequeñas.
* Fáciles de revisar.

Evita migraciones gigantescas que mezclen demasiados cambios.

Considera estrategias para modificar tablas grandes sin downtime.

---

# 12. Performance

Diseña desde el principio para evitar problemas comunes:

* N+1 queries.
* Queries innecesarias.
* Over-fetching.
* Paginación ineficiente.
* Índices faltantes.
* Consultas lentas.
* Renderizado excesivo.
* Assets innecesarios.

Utiliza Pagy correctamente.

Explica cuándo utilizar:

* `includes`
* `preload`
* `eager_load`
* `joins`
* `left_joins`

No optimices prematuramente, pero sí evita malas prácticas conocidas.

---

# 13. Frontend

Utiliza Tailwind CSS + DaisyUI como base.

Integra:

### Tom Select

Para selects avanzados:

* Búsqueda.
* Multi-select.
* AJAX cuando sea necesario.
* Estados de carga.
* Empty states.

### Flatpickr

Para:

* Dates.
* Date ranges.
* Datetime.
* Time.

Debe existir una integración consistente con Rails forms.

### ApexCharts

Crear una capa reutilizable para gráficos.

Debe contemplar:

* Line charts.
* Bar charts.
* Area charts.
* Pie/Donut charts.
* Empty states.
* Loading states.
* Responsive behavior.

Evita colocar configuraciones enormes directamente dentro de las vistas.

---

# 14. JavaScript

Define una estrategia clara de JavaScript compatible con la arquitectura moderna de Rails.

Evalúa cuidadosamente:

* Hotwire.
* Turbo.
* Stimulus.
* Importmap.
* JavaScript bundling cuando realmente sea necesario.

No agregues Node/Webpack/Vite simplemente porque "todo proyecto moderno lo utiliza".

Elige la alternativa que proporcione mejor:

* Mantenimiento.
* Performance.
* Simplicidad.
* Seguridad.
* Compatibilidad futura.
* Developer Experience.

Explica la decisión.

---

# 15. Componentización

Define una estrategia para componentes de UI.

Quiero poder escribir algo conceptualmente similar a:

```erb
<%= render "components/button",
           text: "Guardar",
           variant: :primary %>
```

o una alternativa mejor si existe.

La estrategia debe evitar:

* Partial explosion.
* Componentes excesivamente pequeños.
* Lógica de negocio en componentes visuales.
* Duplicación.

Define claramente qué debe ser:

* Partial.
* Helper.
* ViewComponent, si realmente lo consideras necesario.
* Stimulus controller.
* CSS component.
* Service object.

---

# 16. Formularios

Diseña una estrategia reutilizable para formularios Rails.

Debe contemplar:

* Labels.
* Inputs.
* Selects.
* Errors.
* Help text.
* Required fields.
* Validation messages.
* Accessibility.
* Focus.
* Disabled state.
* Loading state.
* Submit buttons.

La experiencia debe sentirse consistente en todo el sistema.

---

# 17. Tablas administrativas

Diseña un componente de tabla reutilizable con:

* Responsive behavior.
* Sorting.
* Filtering.
* Search.
* Pagination.
* Empty state.
* Loading state.
* Row actions.
* Bulk actions.
* Column alignment.
* Status badges.

Debe evitarse crear una tabla completamente diferente para cada módulo.

---

# 18. Dashboard

Crear un dashboard inicial profesional que sirva como demostración del boilerplate.

Debe incluir:

* KPI cards.
* Charts.
* Recent activity.
* Notifications.
* Quick actions.
* Summary information.

No utilizar datos reales.

Utilizar datos de ejemplo claramente identificados.

---

# 19. Auditoría

Diseña una estrategia para registrar eventos importantes:

```text
User
Action
Resource
Resource ID
Timestamp
IP
User Agent
Changes
```

Debe considerarse:

* Seguridad.
* Privacidad.
* Retención.
* Performance.
* Consultabilidad.

No registrar secretos, passwords ni información sensible innecesaria.

Puedes proponer una gema de auditoría si realmente aporta valor, pero analiza primero las alternativas.

---

# 20. Observabilidad

Diseña una base para:

* Application logs.
* Structured logging.
* Error tracking.
* Performance monitoring.
* Database query monitoring.
* Background job monitoring.

La solución debe poder integrarse posteriormente con herramientas externas sin acoplar demasiado la aplicación.

---

# 21. Background Jobs

Define una estrategia para trabajos asíncronos.

Considera:

* Active Job.
* Solid Queue u otra alternativa compatible con Rails.
* Retries.
* Idempotency.
* Failed jobs.
* Logging.
* Monitoring.

No agregues Redis u otra infraestructura si Rails/PostgreSQL pueden resolver adecuadamente el caso inicial.

---

# 22. Testing

El boilerplate debe iniciar con una estrategia seria de testing.

Evalúa:

* RSpec vs Minitest.
* FactoryBot.
* Faker.
* Shoulda Matchers cuando aporte valor.
* System tests.
* Request tests.
* Model tests.
* Policy tests.

Define qué debe probarse y qué NO vale la pena probar.

Prioriza tests que protejan comportamiento real.

---

# 23. Calidad de código

Configura herramientas como:

* RuboCop.
* Brakeman.
* Bundler Audit u alternativa actual.
* StandardRB si consideras que es mejor opción.
* ESLint si realmente aplica.
* Prettier si realmente aplica.

No agregues herramientas redundantes.

Define una estrategia coherente.

---

# 24. CI/CD

Diseña una configuración preparada para CI.

Debe verificar como mínimo:

```text
Dependencies
↓
Lint
↓
Security scan
↓
Tests
↓
Assets
↓
Build
```

Puede utilizarse GitHub Actions u otra solución, pero evita acoplar innecesariamente el boilerplate a un proveedor.

---

# 25. Environment configuration

Define claramente:

```text
development
test
production
```

y cómo manejar:

* Environment variables.
* Credentials.
* Secrets.
* Database URLs.
* External services.
* Feature flags.

Nunca colocar secretos directamente en el repositorio.

---

# 26. Docker

Evalúa si Docker debe formar parte del boilerplate.

Si lo consideras conveniente, proporciona:

* Dockerfile.
* docker-compose para desarrollo.
* PostgreSQL.
* Health checks.
* Volúmenes.
* Variables de entorno.

Pero evita que Docker agregue complejidad innecesaria al desarrollo local.

---

# 27. Documentación

El boilerplate debe incluir documentación profesional.

Como mínimo:

```text
README.md
CONTRIBUTING.md
SECURITY.md
CHANGELOG.md
```

Documenta:

* Instalación.
* Requisitos.
* Configuración.
* Desarrollo.
* Testing.
* Deployment.
* Arquitectura.
* Convenciones.
* Agregar nuevos módulos.
* Agregar nuevos permisos.
* Agregar componentes.
* Agregar gráficos.
* Agregar filtros.
* Actualizar dependencias.

Un desarrollador nuevo debería poder comenzar a trabajar rápidamente.

---

# 28. Convenciones

Define convenciones para:

* Ruby.
* Rails.
* Models.
* Controllers.
* Policies.
* Services.
* Queries.
* Jobs.
* Views.
* Partials.
* Components.
* Stimulus controllers.
* JavaScript.
* CSS.
* Database.
* Tests.

Evita que cada desarrollador cree su propia arquitectura dentro del mismo proyecto.

---

# 29. Internacionalización

Preparar el sistema para múltiples idiomas.

Inicialmente puede utilizarse:

```text
es
en
```

Considera:

* Rails I18n.
* Validation messages.
* Date formats.
* Number formats.
* UI strings.
* Time zones.

No hardcodear textos visibles al usuario cuando deberían ser traducibles.

---

# 30. Accesibilidad

Aplicar buenas prácticas WCAG.

Considera:

* Semantic HTML.
* Keyboard navigation.
* Focus states.
* Labels.
* ARIA cuando sea necesario.
* Color contrast.
* Screen readers.
* Modals.
* Dropdowns.
* Forms.
* Tables.

La accesibilidad debe formar parte del Design System y no ser un parche posterior.

---

# 31. Responsive Design

El sistema debe funcionar correctamente en:

* Desktop.
* Laptop.
* Tablet.
* Mobile.

No basta con hacer que "no se rompa".

Debe diseñarse específicamente la experiencia móvil para:

* Sidebar.
* Tables.
* Forms.
* Modals.
* Navigation.
* Cards.
* Charts.

---

# 32. Arquitectura preparada para el futuro

Analiza explícitamente cómo evolucionaría el boilerplate si:

* Crece de 10 a 500 usuarios.
* Crece de 500 a 50,000 usuarios.
* La base de datos alcanza millones de registros.
* Aumenta considerablemente el número de módulos.
* Se agregan APIs.
* Se agregan integraciones externas.
* Se requiere multi-tenancy.
* Se requiere SSO.
* Se requiere 2FA.
* Se requiere almacenamiento externo.
* Se requiere procesamiento asíncrono intensivo.
* Se requiere separar determinados componentes.

No implementes todo eso ahora.

Explica **qué decisiones tomadas hoy facilitan esas evoluciones mañana**.

---

# 33. Actualizaciones y longevidad

Quiero que el boilerplate pueda mantenerse durante muchos años.

Diseña una estrategia para:

* Actualizar Ruby.
* Actualizar Rails.
* Actualizar gems.
* Actualizar JavaScript.
* Actualizar Tailwind.
* Actualizar DaisyUI.
* Actualizar PostgreSQL.

Evita dependencias excesivamente acopladas.

Cada dependencia adicional debe justificar su existencia.

---

# 34. Estructura de módulos

Propón una estructura inicial similar a:

```text
app/
├── controllers/
├── models/
├── policies/
├── services/
├── queries/
├── jobs/
├── mailers/
├── helpers/
├── views/
│   ├── layouts/
│   ├── components/
│   └── ...
├── javascript/
│   ├── controllers/
│   ├── components/
│   └── ...
└── assets/
```

Pero no asumas que esta estructura es necesariamente la mejor.

Si propones otra, explica por qué.

---

# 35. Primer módulo funcional

Después de crear la base, implementar un módulo de demostración:

## Usuarios

Debe incluir:

* Listado.
* Búsqueda.
* Filtros.
* Paginación.
* Alta.
* Edición.
* Visualización.
* Activar/desactivar.
* Autorización mediante Pundit.
* Validaciones.
* Estados.
* Empty states.
* Confirmaciones.
* Auditoría básica.

Debe servir como **referencia arquitectónica** para futuros módulos.

---

# 36. Reglas importantes

Durante todo el desarrollo:

### NO

* Generes código innecesario.
* Inventes APIs.
* Utilices gems sin justificar.
* Introduzcas patrones complejos sin necesidad.
* Dupliques lógica.
* Hardcodees configuraciones.
* Mezcles responsabilidades.
* Ignorar errores de seguridad.
* Ocultar decisiones importantes.
* Avances varias fases sin aprobación.

### SÍ

* Prioriza código simple.
* Explica decisiones.
* Mantén consistencia.
* Piensa en producción.
* Piensa en mantenimiento.
* Piensa en futuros desarrolladores.
* Piensa en actualizaciones.
* Piensa en seguridad desde el inicio.
* Utiliza las capacidades nativas de Rails siempre que sean suficientes.
* Mantén el boilerplate fácilmente clonable.
* Mantén las dependencias bajo control.

---

# 37. Formato de trabajo obligatorio

Antes de comenzar, entrega:

## Fase 0 — Architecture Decision Record

Incluye:

1. Objetivos.
2. Non-goals.
3. Stack recomendado.
4. Versiones.
5. Arquitectura.
6. Estructura de carpetas.
7. Estrategia frontend.
8. Estrategia de autenticación.
9. Estrategia de autorización.
10. Estrategia de testing.
11. Estrategia de seguridad.
12. Estrategia de componentes.
13. Estrategia de deployment.
14. Riesgos.
15. Trade-offs.
16. Decisiones que deliberadamente NO implementaremos todavía.

Después proporciona un:

## Roadmap

Por ejemplo:

```text
Fase 0 — Arquitectura
Fase 1 — Inicialización Rails
Fase 2 — Base de datos
Fase 3 — Frontend / Design System
Fase 4 — Layout administrativo
Fase 5 — Authentication
Fase 6 — Authorization
Fase 7 — Componentes
Fase 8 — Forms
Fase 9 — Tables / Filters / Pagy
Fase 10 — Charts
Fase 11 — Dashboard
Fase 12 — Usuarios
Fase 13 — Auditoría
Fase 14 — Testing
Fase 15 — Security hardening
Fase 16 — CI/CD
Fase 17 — Docker / Deployment
Fase 18 — Documentation
Fase 19 — Final architecture review
```

Puedes modificar este roadmap si existe una secuencia mejor.

---

# 38. Criterio de aceptación

Al finalizar, el resultado debe sentirse como:

> "Una base profesional que un equipo senior podría utilizar como punto de partida para desarrollar múltiples aplicaciones administrativas durante los próximos años."

No debe sentirse como:

> "Un CRUD de Rails con Tailwind."

La calidad debe evaluarse en:

* Arquitectura.
* Seguridad.
* UX.
* UI.
* Código.
* Testing.
* Performance.
* Developer Experience.
* Documentación.
* Escalabilidad.
* Mantenibilidad.
* Evolución futura.

---

# 39. Regla final

**No empieces generando código.**

Primero analiza el problema como arquitecto.

Presenta:

1. Evaluación del stack solicitado.
2. Mejoras recomendadas.
3. Versiones recomendadas.
4. Arquitectura propuesta.
5. Decisiones y trade-offs.
6. Estructura del proyecto.
7. Roadmap completo.
8. Riesgos técnicos.

Después de eso, espera mi aprobación para comenzar con la **Fase 1**.

Cada fase debe dejar el proyecto en un estado funcional, coherente y verificable antes de continuar.
