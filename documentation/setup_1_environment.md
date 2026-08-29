# Setup: (MacBook entorno de desarrollo)

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