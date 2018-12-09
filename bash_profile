#!/bin/bash

# If not running ractively, don't do anything
[ -z "$PS1" ] && return

# tab completions for sudo
complete -cf sudo

shopt -s nocaseglob     # case-insensitive path expansion globbing
shopt -s checkwinsize   # check the window size after each command, and
                        # update LINES and COLUMNS if the size has changed.
shopt -s histappend     # append history instead of rewriting it
shopt -s hostcomplete   # tab-completion of hostnames after @
shopt -s cdspell        # autocorrect typos in path names when using `cd`
shopt -s cmdhist        # save multi-line commands as one command

silence () {
  "$@" 2> /dev/null > /dev/null;
}

addpath () {
  [[ -d "$1" ]] && PATH="$1:${PATH}"
}

include () {
  # shellcheck source=/dev/null
  [[ -f "$1" ]] && source "$1"
}

evaluate () {
  [[ -x "$(command -v $1)" ]] && eval "$2"
}

setup_ssh () {
  # if not started, start ssh-agent.
  if ! silence pgrep 'ssh-agent'; then
  silence ssh-agent
  fi

  # add keys if ssh directory exists.
  if [ -d "$HOME/.ssh" ]; then
    find "$HOME/.ssh" -name '*\.pem' | silence xargs ssh-add
  fi
}

addpath "$HOME/.bin"
addpath "/usr/local/opt/gnu-tar/libexec/gnubin"
addpath "/usr/local/opt/grep/libexec/gnubin"
addpath "/usr/local/opt/coreutils/libexec/gnubin"
addpath "/usr/local/opt/openssl/bin"
addpath "/usr/local/opt/python/libexec/bin"
addpath "/usr/local/opt/node@8/bin"

include "/usr/local/etc/bash_completion.d"
include "/usr/local/bin/virtualenvwrapper_lazy.sh"
include "$HOME/.fzf.bash"
include "$HOME/.nvm/nvm.sh"
include "$HOME/.bash_profile.local"
include "$HOME/.iterm2_shell_integration.bash"

evaluate "rbenv" "$(rbenv init -)"
evaluate "thefuck" "$(thefuck --alias)"
evaluate "aws" "$(complete -C aws_completer aws)"
evaluate "pyenv" "$(pyenv init -)"
evaluate "direnv" "$(direnv hook bash)"

if [ -x "$(command -v dircolors)" ]; then
  eval "$(dircolors -b $HOME/.dircolors)"
fi

if [ -x "$(command -v network)" ]; then
  complete -W "$(network listcommands)" 'network'
fi

if [ -x "$(command -v brew)" ]; then
  include "$(brew --prefix)/etc/bash_completion"
fi

if ! [[ "$PROMPT_COMMAND" =~ _direnv_hook ]]; then
  PROMPT_COMMAND="_direnv_hook;$PROMPT_COMMAND";
fi

# highlighting inside manpages and elsewhere
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

# don’t clear the screen after quitting a manual page.
export MANPAGER="less -X"

# make match highlight color green
export GREP_COLOR='1;32'

# stfu direnv
export DIRENV_LOG_FORMAT=

export WORKON_HOME=$HOME/.virtualenvs

# don't create .pyc files.
export PYTHONDONTWRITEBYTECODE=true
export TERM=xterm-256color

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:c:[ \t]*"

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

export EDITOR='nano'
export VISUAL='atom'

export PS1="\h \[\e[1;32m\]\w\[\e[0m\] [\A] > "

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

alias d="cd ~/Desktop"
alias p="cd ~/Projects"
alias r="cd ~/Repos"
alias c="clear"
alias e="exit"
alias g="git"
alias h="history"

# always ask before replacing
alias cp='cp -i'

alias l="ls"
alias sl="ls"
alias la="ls -a"

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias rsync="rsync -v -P"
alias sudo="sudo "
alias tree='find . -type d | sed -e "s/[^-][^\/]*\//  |/g;s/|\([^ ]\)/|-\1/"'

# check if coreutils is installed (os-x) or if os contains gnu, if so we can
# use these aliases.
if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ] || [[ $OSTYPE =~ gnu ]]; then
  alias ll="ls --human-readable --almost-all -l"
  alias ls="ls --color=auto --group-directories-first -X --classify -G"
fi
# virtualenvwrapper
if [ -x "$(command -v virtualenvwrapper.sh)" ]; then
  alias vmk='mkvirtualenv'
  alias vrm='rmvirtualenv'
  alias vcd='cdvirtualenv'
fi

# os-x specific
if [[ $OSTYPE =~ darwin ]]; then
  alias o="open ./"
  alias fixcamera='sudo killall VDCAssistant'
  alias fixspeak='killall -9 com.apple.speech.speechsynthesisd'
fi

if [ -x "$(command -v bat)" ]; then
  alias cat="bat --paging never"
fi

if [ -x "$(command -v git)" ]; then
  alias ga='git add'
  alias gd='git diff'
  alias gs='git status'
fi

setup_ssh
