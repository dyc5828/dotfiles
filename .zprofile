# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:$HOME/.docker/bin"
# End of Docker Desktop section.

[[ $(uname -m) == 'arm64' ]] && brew_prefix='/opt/homebrew' || brew_prefix='/usr/local'
# echo $brew_prefix
eval "$(${brew_prefix}/bin/brew shellenv)"

eval "$(pyenv init --path)"
eval "$(frum init)"
