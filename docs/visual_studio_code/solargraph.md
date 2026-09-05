Para integrar **Solargraph** (el servidor de lenguaje para autocompletado e intellisense en Ruby) en el entorno de desarrollo, lo añadiremos al grupo correspondiente en tu proyecto junto a las herramientas que ya configuramos previamente como `rubocop-rspec`.

**1. Añadir la gema al proyecto**
Ejecuta el siguiente comando para agregar la gema exclusivamente al entorno de desarrollo sin requerirla durante el arranque:

```bash
bundle add solargraph --group "development"

```

*(Si prefieres hacerlo manual, añade `gem "solargraph", require: false` dentro del bloque `group :development do` en tu `Gemfile` y ejecuta `bundle install`).*

**2. Generar la configuración base**
Crea el archivo de configuración `.solargraph.yml` en la raíz del proyecto para definir las reglas de inspección:

```bash
bundle exec solargraph config

```

**3. Generar la documentación de las dependencias (YARD)**
Para que Solargraph pueda ofrecerte autocompletado preciso analizando el código de Rails 8.1, Ruby 3.4.10 y el resto de tus gemas, debes compilar la documentación localmente:

```bash
bundle exec yard gems

# 1. Cargar e indexar las gemas instaladas (maneja STDLIB automáticamente)
solargraph gems

# 2. Mapear el espacio de trabajo del proyecto
solargraph scan
```

2. Actualizar .solargraph.yml

Asegúrate de que tu archivo .solargraph.yml en la raíz incluya las rutas de la aplicación y active la integración con Rails:

```yaml
include:
  - "app/**/*.rb"
  - "lib/**/*.rb"
exclude:
  - "spec/**/*"
  - "test/**/*"
  - "vendor/**/*"
  - ".bundle/**/*"
  - "db/schema.rb"
plugins:
  - rails
```

**4. Actualizar el `.gitignore**`
Es recomendable ignorar la caché que genera el servidor de lenguaje añadiendo esta línea a tu archivo `.gitignore` existente:

```text
# Solargraph
.solargraph.cache

```

Una vez completados estos pasos, solo necesitas reiniciar el servidor de lenguaje en tu editor de texto (VS Code, Neovim, etc.) para que comience a indexar la arquitectura del boilerplate.

- Presiona el atajo Cmd + Shift + P (o F1).
- Escribe Restart seguido del nombre del lenguaje que estás usando.
- Selecciona el comando 'correspondiente de la lista'.

Opcional: Anotaciones YARD para código dinámico

Para que reconozca atributos dinámicos de ActiveRecord (como campos de la tabla o asociaciones) dentro de tus modelos, puedes agregar comentarios YARD sobre la clase:

```ruby
# @attr [String] email_address
# @attr [Role] role
class User < ApplicationRecord
  belongs_to :role
end
```
