# Setup: Project (MacBook entorno de desarrollo)

## Paso 1: Configuración de Base de Datos y Aplicación

Clonar proyecto y entrar en su directorio

```bash
git clone git@github.com:ocoronamx/admin-gem.git
cd admin-gem
```

definir versiones de node, posgres y ruby para asdf

```bash
asdf set postgres 17.0
asdf set ruby 3.4.10
asdf reshim ruby
```

Agregar aliases inteligentes para PostgreSQL con ASDF

```bash
echo '\n# Aliases para PostgreSQL' >> ~/.zshrc
echo "alias pg_init='initdb \"\$(asdf where postgres)/data\"'" >> ~/.zshrc
echo "alias pg_start='pg_ctl -D \"\$(asdf where postgres)/data\" start'" >> ~/.zshrc
echo "alias pg_stop='pg_ctl -D \"\$(asdf where postgres)/data\" stop'" >> ~/.zshrc
echo "alias pg_status='pg_ctl -D \"\$(asdf where postgres)/data\" status'" >> ~/.zshrc
source ~/.zshrc
```

Iniciar PostgreSQL y crear los roles necesarios en la base de datos

```bash
pg_start
psql -U postgres postgres -c "CREATE ROLE ocorona WITH LOGIN SUPERUSER;"
psql -U postgres postgres -c "CREATE ROLE admin_gem WITH CREATEDB LOGIN PASSWORD 'admin-pass';"
```

Instalar y configurar Bundler con la ruta de asdf

```bash
gem install bundler
gem update --system 4.0.19
bundle config build.pg --with-pg-config=$(asdf where postgres)/bin/pg_config
```

Crear el proyecto

```bash
gem install rails -v "~> 8.1"
rails -v
rails new . \
  --database=postgresql \
  --css=tailwind \
  --skip-test \
  --skip-jbuilder
```

Gemfile: Añadir arriba de gem "rails"

```ruby
ruby "3.4.10"
```

Añadir justo debajo de gem "rails", para remediar el CVE de resolv sin esperar a un parche de Ruby y rubocop-rspec:

```ruby
# Corrige CVE-2026-80212 / CVE-2026-80213 (resolv bundled con Ruby 3.4.10).
# Quitar esta línea cuando Ruby publique un 3.4.x con resolv >= 0.7.2 de fábrica.
gem "resolv", ">= 0.7.2"
```

Y en los grupos :development, :test
```ruby
group :development, :test do
  ...
  # Integrates the Rails testing helpers into RSpec.
  gem "rspec-rails"

  # Provides integration between factory_bot and Rails 6.1 or newer
  gem "factory_bot_rails"

  # Data::Faker fork from Perl, generate fake data: names, addresses, phone numbers, etc.
  gem "faker"

  # Code style checking for RSpec files. A plugin for the RuboCop code style enforcing & linting tool.
  gem "rubocop-rspec", require: false
end
```

Añadir rubocop-rspec en .rubocop.yml

```yaml
# Omakase Ruby styling for Rails
inherit_gem: { rubocop-rails-omakase: rubocop.yml }

# require:
  # - rubocop-rspec
plugins:
  - rubocop-rspec

AllCops:
  NewCops: enable  # O usa 'disable' si prefieres ignorar las reglas nuevas de golpe

# Overwrite or add rules to create your own house style
#
# # Use `[a, [b, c]]` not `[ a, [ b, c ] ]`
# Layout/SpaceInsideArrayLiteralBrackets:
#   Enabled: false
```

Añadir estas líneas en .gitignore:

```
# Ignore system files and test coverage reports
.DS_Store
/coverage/
```

### Verificación de consistencia

```bash
bundle install
```

Después de bundle install, confirma la versión de Ruby:

* .tool-versions  → ruby 3.4.10
* .ruby-version   → ruby 3.4.10
* Dockerfile      → ARG RUBY_VERSION=3.4.10

#### Iniciar el servidor

Ahora se pueden correr validaciones e iniciar la aplicación:

```bash
bin/rails db:create db:prepare
bin/rails generate rspec:install
bundle exec rspec               # → 0 examples, 0 failures
bundle exec rubocop             # → sin offenses
bundle exec brakeman            # → 0 warnings
bundle exec bundler-audit check --update   # → 0 vulnerabilities
bin/dev                         # → localhost:3000 sirve la página placeholder con Tailwind
```

En spec/rails_helper.rb, añadir dentro del bloque RSpec.configure do |config|:

```ruby
# para poder escribir create(:user) en vez de FactoryBot.create(:user)
config.include FactoryBot::Syntax::Methods
```