[[ $(uname -m) == 'arm' ]] && brew_prefix='/opt/homebrew' || brew_prefix='/usr/local'
# echo $brew_prefix
eval "$(${brew_prefix}/bin/brew shellenv)"

eval "$(pyenv init --path)"
eval "$(frum init)"
