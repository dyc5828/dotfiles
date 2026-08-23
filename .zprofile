[[ $(uname -m) == 'arm64' ]] && brew_prefix='/opt/homebrew' || brew_prefix='/usr/local'
# echo $brew_prefix
eval "$(${brew_prefix}/bin/brew shellenv)"

# GitHub - all tokens derived from gh CLI keyring auth
export GITHUB_TOKEN="$("${brew_prefix}/bin/gh" auth token)"
export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"

eval "$(pyenv init --path)"
eval "$(frum init)"
