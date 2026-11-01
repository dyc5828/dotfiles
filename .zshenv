# PATH
# export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
# export PATH="$PATH:$GEM_HOME/bin"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$HOME/.local/bin:$HOME/.antigravity/antigravity/bin:$PATH"

# GitHub - all tokens derived from gh CLI keyring auth. In .zshenv so non-login shells get them.
export GITHUB_TOKEN="${GITHUB_TOKEN:-$(/opt/homebrew/bin/gh auth token 2>/dev/null)}"
export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"

# Homebrew
export HOMEBREW_CASK_OPTS="--no-quarantine"

# openssl
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"

# Local/secret overrides
[ -f ~/.zshenv.local ] && source ~/.zshenv.local
