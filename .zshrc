## CONFIG
ZSH_DISABLE_COMPFIX=true
OP_BIOMETRIC_UNLOCK_ENABLED=true #1Password

## PATH
# GEM
export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
export PATH="$PATH:$GEM_HOME/bin"

# Homebrew
export PATH="/usr/local/sbin:$PATH"

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v17)
export PATH=$PATH:$JAVA_HOME/bin

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK=$ANDROID_HOME/ndk/23.1.7779620
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# PHP
#export PATH="$HOMEBREW_PREFIX/opt/php@7.4/bin:$PATH"
#export PATH="$HOMEBREW_PREFIX/opt/php@7.4/sbin:$PATH"
#export LDFLAGS="-L$HOMEBREW_PREFIX/opt/php@7.4/lib"
#export CPPFLAGS="-I$HOMEBEW_PREFIX/opt/php@7.4/include"

## ALIAS

# homebot
alias av=aws-vault
alias dc=docker-compose
alias hbdev="$HOME/code/homebot/hbdev/bin/hbdev"
alias hdev="docker-compose -f $HOME/code/homebot/hbdev/docker-compose.yml -p hbdev"

# cd/z
alias ~='z '
alias ..='z ..'
alias ...='z ../..'

# clear
alias c='clear'

# diff
alias diff='riff'

# edit
alias n='nano'

# date
alias dateutc='date -u -Iseconds'

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
alias gds='gd --compact-summary'
alias gph='g push'
alias gpl='g pull'
alias gplr='gpl --rebase'
alias gplm='gpl --no-rebase'
alias gplf='gpl --ff-only'
alias gl='g log'
alias gr='g reset'
alias grs='gr --soft'
alias grh='gr --hard'
alias gsh='g stash'
alias gshl='gsh list'
alias gshp='gsh pop'
alias gsw='git switch'

# ls/eza
alias e='eza'
alias le='eza --icons'
alias l='le -a'
alias ll='l -l'
alias lt='l --tree'

# cat/bat
alias cat='bat --paging=never'
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

# xcode
alias sim='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

# ai
alias fabric=fabric-ai

## SHELL
eval "$(starship init zsh)"
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# eval $(thefuck --alias)

export NVM_COMPLETION=true
export NVM_AUTO_USE=true
# export NVM_LAZY_LOAD=true

source ~/.zsh/zsh-nvm/zsh-nvm.plugin.zsh
source ~/.zsh/zsh-completion-generator/zsh-completion-generator.plugin.zsh

fpath=(
    ~/.docker/completions
    ~/.zfunc
    $fpath
)


## COMMAND

function reload () {
	source ~/.zprofile
	source ~/.zshenv
	source ~/.zshrc
	echo "SHELL RELOADED!"
}

function dot {
   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
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

function gsha () {
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

function gsw_origin () {
	gsw -c ${1} origin/${1}
}

function gsw_pr () {
	pr_num=${1}
	branch=pr${pr_num}
	i=0
	
	echo "Checking if ${branch} exists.."
	branch_hash=`git show-ref refs/heads/${branch}`


	while [ -n "$branch_hash" ]
	do
		echo "${branch}_${i} exists already."

		((i=i+1))
		echo "Checking next name in sequence: ${branch}_${i+1}.."
		branch_hash=`git show-ref refs/heads/${branch}_${i}`
	done


	pr_branch=${branch}_${i} 
	echo "Checking out PR #${pr_num} to new branch ${pr_branch}.."
	git fetch origin pull/${pr_num}/head:${pr_branch}
	git switch ${pr_branch}
	

	# if [ -n "$branch_hash" ]; then
	# 	echo "${branch} exits"
	# 	# echo "Creating branch ${branch}"
	# 	# gsw -c ${branch} origin/master
	# 	# git pull origin pull/${num}/head
	# else
	# 	echo "no ${branch}"
	# 	# echo "Switching to branch ${branch}"
	# 	# gsw ${branch}
	# fi
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

## LOAD completions
autoload -Uz +X compinit
compinit

# initialize z after compinit for auto complete suggestions
eval "$(zoxide init zsh)"
