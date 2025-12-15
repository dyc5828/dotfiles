# Githubb
export GITHUB_TOKEN=

# Homebrew
export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"

# Gemini API
export GEMINI_API_KEY=

# openssl
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"

# Homebot
## Postgres
export PGHOST='127.0.0.1'
export PGPORT='5432'
export PGUSER='postgres'

## bundler credentials for sidekiq enterprise
BUNDLE_ENTERPRISE__CONTRIBSYS__COM=

# PATH
# export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
# export PATH="$PATH:$GEM_HOME/bin"
export PATH="$HOME/.local/bin:$PATH"
