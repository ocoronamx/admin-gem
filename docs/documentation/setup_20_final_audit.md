## Lo que está sólido

RBAC consistente de punta a punta — cada controlador real (`roles`, `users`, `audit_logs`) llama `authorize`/`policy_scope`, sin excepciones sueltas. El patrón de ir encontrando y cerrando huecos en cada fase (el `PermissionResource` que nunca se incluyó, el `authorize` que faltaba en `index`, el bug de `Filterable`, el CSP rompiendo la leyenda de ApexCharts) terminó dejando muy poco sin revisar dos veces. `Filterable`, `components/table`, `AdminFormBuilder` y el patrón `pagy(:offset, ...)` se reusan sin fricción en los tres recursos reales — Setup 13 cumplió lo de "módulo de referencia" en la práctica, no solo en el nombre. CI corre lint→seguridad→tests→build como una sola pipeline nativa de Rails 8.1, sin duplicar lógica en YAML y Ruby a la vez.

## Para arreglar ahora (bugs/inconsistencias reales)

1. **`config/routes.rb` tiene una ruta muerta**: `get "dashboard/index"` es el leftover del generador (`rails generate controller Dashboard index`) — `root to: "dashboard#index"` ya cubre eso. Dos URLs sirviendo lo mismo, sin razón.
   ```ruby
   # Borrar esta línea, la primera del archivo:
   get "dashboard/index"
   ```

2. **`docs/documentation/setup_99_TODO.md` está desactualizado** — sigue mostrando Setup 17 como CURRENT. Con Setup 18 documentado (no aplicado) y 19 pospuesto a propósito, el TODO debería reflejar eso explícitamente, no solo "pendiente":
   ```markdown
   * Setup 17 — CI/CD                           hecho

   ## CURRENT:
   * Setup 20 — Revisión final de arquitectura

   ## PENDIENTE A PROPÓSITO (no bloquea, se retoma cuando aplique):
   * Setup 18 — Docker / Deployment             (documentado en docs/documentation/, sin aplicar — sin servidor/dominio todavía)
   * Setup 19 — Documentation                   (README, CONTRIBUTING, SECURITY, CHANGELOG, docs/adr/ — se hace junto con 18)
   ```

3. **`docs/setup_13_users.md` está mal ubicado** — es el único doc de fase que vive directo en `docs/` en vez de `docs/documentation/`. Un `mv` lo resuelve:
   ```bash
   git mv docs/setup_13_users.md docs/documentation/setup_13_users.md
   ```

4. **Sidebar: `policy(Role).show?` en vez de `policy(Role).index?`** para decidir si mostrar el link a una lista. Hoy da lo mismo (las dos resuelven al mismo `permitted?(:view)`), pero semánticamente `index?` es lo correcto para "¿puedo ver la lista?" — si algún día una policy separa esos dos casos, este nav queda mostrando (o escondiendo) el link equivocado sin que nadie lo note hasta que alguien haga click.

## Para arreglar cuando tengas un rato (cosmético, no urgente)

- **`gem "image_processing"` en el Gemfile no se usa en ningún lado** — es el default de `rails new` para Active Storage, pero no hay ni un upload en toda la app. Si no vas a agregar avatares/adjuntos pronto, es peso muerto; si sí, dejalo.
- **`gem "simplecov"` vive suelto al final del Gemfile**, fuera del bloque `group :development, :test do`. Funciona igual, pero conviene moverlo adentro del mismo grupo que `rspec-rails`/`brakeman` por prolijidad.
- **`.rubocop.yml`** tiene un `# require: / # - rubocop-rspec` comentado que quedó muerto desde que `plugins:` lo reemplazó dos líneas después.
- `script/` está vacío (leftover de `rails new`, cero riesgo, se puede borrar o dejar).
- `IconsHelper` tiene un `document_search_check` que no until parece usarse en ningún view — o se usa en algo que no vi, o es un ícono de más.

## Deliberadamente pendiente (ya documentado, no es deuda oculta)

- **Setup 18 (Docker/Kamal)**: documentado en chat, `assume_ssl` sigue comentado y no hay `docker-compose.yml` — confirmado que no se aplicó, consistente con "no tengo dónde desplegar todavía". Cuando tengas servidor, es aplicar lo que ya quedó escrito.
- **Setup 19 (README/CONTRIBUTING/SECURITY/CHANGELOG/docs/adr)**: pospuesto a propósito, se hace junto con el deploy real.
- **"Último usuario con `manage`"**: `UserPolicy#toggle_active?` te protege de desactivarte a vos mismo, pero no hay protección genérica contra dejar el sistema sin ningún usuario con `users.manage` (quedó anotado como decisión explícita en Setup 13, no como olvido).
- **`auditable_spec.rb`** tiene el test frágil por el `let` lazy que mencioné en su momento — sigue pasando, sigue frágil, tu decisión si vale la pena hacerlo explícito con `let!`.

## Cobertura de tests — huecos menores

- `AuditLogPolicy` no tiene spec propio (es una subclase vacía, pero `RolePolicy`/`UserPolicy` sí lo tienen — por consistencia, valdría uno chico).
- `/styleguide` no tiene ningún test — dev-only, prioridad baja, pero es la única ruta real de la app con cero cobertura.

## Veredicto

El proyecto arranca, pasa sus tests, y cada decisión de arquitectura tiene su razonamiento escrito en algún lado — es revisable por otra persona sin tener que preguntarte por qué se hizo algo. Los hallazgos de arriba son pulido, no reconstrucción: nada de esto bloquea usar el boilerplate hoy tal como está. Si querés, te armo los fixes del punto "Para arreglar ahora" como un commit único — son cuatro cambios chicos y no interfieren entre sí.