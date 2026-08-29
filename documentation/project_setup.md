# MacBook Setup para desarrollo

## Paso 1: Preparación del Sistema (Arquitectura y SSH)

Dar temporalmente el rol de administrador al usuario y reiniciar.

Instalar Command Line Tools

```bash
xcode-select --install
```

Instalar Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Actualizar zsh e instalar ohmyzsh

```bash
brew install zsh
"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Instalar editor de texto y terminal con pantalla dividida

```bash
brew install --cask pulsar
brew install --cask iterm2
```

## Paso 2: Configurar Git y dependencias de compilación

Preparar llaves RSA y configurar Gitlab

```bash
# Crear el directorio SSH si no existe y generar tu llave
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
ssh-keygen -t rsa -b 4096 -C "developer@mail.com" -f $HOME/.ssh/id_rsa -N ""

# IMPORTANTE: Copia tu llave pública y agrégala a tu cuenta de GitLab antes de seguir
cat $HOME/.ssh/id_rsa.pub
```

Instalar dependencias necesarias para compilar versiones antiguas de Ruby y Postgres

```bash
brew install openssl@1.1 openssl@3 readline libyaml gmp autoconf coreutils zlib curl ossp-uuid pkg-config icu4c
echo 'export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/opt/curl/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/opt/icu4c@78/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/opt/icu4c@78/sbin:$PATH"' >> ~/.zshrc
source .zshrc
export LDFLAGS="-L/opt/homebrew/opt/readline/lib -L/opt/homebrew/opt/zlib/lib -L/opt/homebrew/opt/curl/lib -L/opt/homebrew/opt/icu4c@78/lib"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include -I/opt/homebrew/opt/zlib/include -I/opt/homebrew/opt/curl/include -I/opt/homebrew/opt/icu4c@78/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c@78/lib/pkgconfig"
```

## Paso 3: Instalar y Configurar el Gestor Unificado (asdf)

Instalar asdf mediante Homebrew

```bash
brew install asdf
brew info asdf

echo -e "\n# ASDF Configuration (asdf v0.16+)" >> $HOME/.zshrc
echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> $HOME/.zshrc
source $HOME/.zshrc
asdf --version
```

Instalar los plugins para Postgres y Ruby

```bash
asdf plugin add postgres
asdf plugin add ruby
```

## Paso 4: Instalación de las Versiones de Software

Instalar dependencias


Ejecutaremos la compilación forzando la arquitectura correcta y las banderas de OpenSSL

```bash
# Exportar rutas de Homebrew nativo (ARM64)
export LDFLAGS="-L/opt/homebrew/opt/readline/lib -L/opt/homebrew/opt/zlib/lib -L/opt/homebrew/opt/curl/lib -L/opt/homebrew/opt/icu4c@78/lib -L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include -I/opt/homebrew/opt/zlib/include -I/opt/homebrew/opt/curl/include -I/opt/homebrew/opt/icu4c@78/include -I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c@78/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# Instalar Postgres 17.0
PKG_CONFIG_PATH="$(brew --prefix icu4c)/lib/pkgconfig" \
POSTGRES_EXTRA_CONFIGURE_OPTIONS="--with-openssl --with-includes=$(brew --prefix openssl@3)/include --with-libraries=$(brew --prefix openssl@3)/lib" \
asdf install postgres 17.0

# Instalar y activar Ruby 3.4.10
LDFLAGS="-L$(brew --prefix libyaml)/lib -L$(brew --prefix openssl@3)/lib" \
CFLAGS="-I$(brew --prefix libyaml)/include -I$(brew --prefix openssl@3)/include" \
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline)" \
asdf install ruby 3.4.10

# POSTGRES_EXTRA_CONFIGURE_OPTIONS="--with-openssl" asdf install ruby 3.4.10

```

## Paso 5: Configuración de Base de Datos y Aplicación

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
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

require:
  - rubocop-rspec

# Cualquier ajuste de estilo propio del equipo se documenta aquí,
# nunca como comentarios `# rubocop:disable` sueltos sin justificación.
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

##### 6. Iniciar el servidor

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

Instalar dependencias

```bash
brew install imagemagick
bundle install
npm install -g yarn
yarn install
asdf reshim ruby
```

Crear application.yml y definir configuracion de PostgreSQL

```bash
touch config/application.yml
echo "DB_HOST: 'localhost'" >> config/application.yml
echo "DB_DATABASE: 'admin-gem'" >> config/application.yml
echo "DB_USERNAME: 'admin_gem'" >> config/application.yml
echo "DB_PASSWORD: 'admin-pass'" >> config/application.yml
echo "DB_PORT: '5432'" >> config/application.yml
```

Agregar master.key

```bash
touch config/master.key
echo '7fc8646b422120f0d68a87873618ae15' >> config/master.key
```