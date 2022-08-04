## CONFIG
ZSH_DISABLE_COMPFIX=true

## PATH
# GEM
export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
export PATH="$PATH:$GEM_HOME/bin"

# Homebrew
export PATH="/usr/local/sbin:$PATH"

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v11.0.15)
export PATH=$PATH:$JAVA_HOME/bin

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# PHP
export PATH="/usr/local/opt/php@7.4/bin:$PATH"
export PATH="/usr/local/opt/php@7.4/sbin:$PATH"
export LDFLAGS="-L/usr/local/opt/php@7.4/lib"
export CPPFLAGS="-I/usr/local/opt/php@7.4/include"

## ALIAS

# dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dot='dotfiles'

# cd
alias ~='cd '
alias ..='cd ..'
alias ...='cd ../..'

# clear
alias c='clear'

# edit
alias n='nano'

# git
alias g='git'
alias gs='g status'
alias ga='g add'
alias gaa='git add --all'
alias gb='g branch'
alias gbl='gb --list'
alias gbd='gb --delete'
alias gc='git commit'
alias gca='gc --amend'
alias gcm='gc -m'
alias gco='g checkout'
alias gcp='g cherry-pick'
alias gd='g diff'
alias gds= 'gd --compact-summary'
alias gph='g push'
alias gpl='g pull'
alias gl='g log'
alias gr='g reset'
alias grs='gr --soft'
alias grh='gr --hard'
alias gsh='g stash'
alias gshl='gsh list'
alias gshp='gsh pop'

# arc
alias a='arc'
alias aw='a work'
alias ab='a branch'
alias ad='a diff'
alias ap='a patch'
alias al='a land'
alias ac='git branch | cut -c3- | grep arcpatch- | xargs -n1 git branch -D'

# colorls
alias lc='colorls'
alias l='lc -A --sd'
alias ll='l -l'
alias lt='l --tree'

# xcode
alias sim='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

## PLUGIN
eval "$(starship init zsh)"
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# eval $(thefuck --alias)
source $(dirname $(gem which colorls))/tab_complete.sh

export NVM_COMPLETION=true
export NVM_AUTO_USE=true
# export NVM_LAZY_LOAD=true

source ~/.zsh/zsh-nvm/zsh-nvm.plugin.zsh
source ~/.zsh/zsh-completion-generator/zsh-completion-generator.plugin.zsh



## COMMAND

function reload () {
	source ~/.zprofile
	source ~/.zshenv
	source ~/.zshrc
	echo "SHELL RELOADED!"
}

function count_files () {
	name=${1:-"*"}
	dir=${2:-.}
	echo "Counting files with '$name' in '$dir'"

	find $dir -mindepth 1 -type f -name $name -exec printf x \; | wc -c
}

function gr_head () {
	gr "HEAD~${1:-1}"
}

function gsha {
	git stash apply stash@{$1}
}

function gshd () {
	git stash drop stash@{$1}
}

function gsh_unstaged () {
	gcm "${1:-'temp'}"
	ga .
	gsh
	gr HEAD~1
	ga .
}

function g_skip () {
	git update-index --skip-worktree $1
}

function g_unskip () {
	git update-index --no-skip-worktree $1
}

function gls_skipped () {
	git ls-files -t|grep "^S"
}

function glsr_tags () {
	# git ls-remote --tags origin | cut -d/ -f3
	git ls-remote --tags ${1:-"origin"}
}

function ls_port () {
	lsof -i :$1
}

function ps_find () {
	ps ax | grep $1
}

function kill_port () {
	kill $(lsof -ti :$1)
}

## LOAD

autoload -Uz compinit
compinit -u
