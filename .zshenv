# PATH
# export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
# export PATH="$PATH:$GEM_HOME/bin"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$HOME/.local/bin:$HOME/.antigravity/antigravity/bin:$PATH"

# Homebrew
export HOMEBREW_CASK_OPTS="--no-quarantine"
export CLOUDSDK_PYTHON=/opt/homebrew/bin/python3.13

# openssl
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"

# Local/secret overrides
[ -f ~/.zshenv.local ] && source ~/.zshenv.local
