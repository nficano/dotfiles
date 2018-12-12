#!/bin/bash

if [[ $- != *i* ]] ; then
  return
fi

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

includeif () {
  [[ -d "$1" ]] && PATH="$1:${PATH}"
}

sourceif () {
  # shellcheck source=/dev/null
  [[ -f "$1" ]] && source "$1"
}

evalif () {
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

os_is_darwin () {
  [[ $(uname -s) == "Darwin" ]]
}

os_is_linux () {
  [[ $(uname -s) == "Linux" ]]
}

findmyiphone () {
  curl \
    -d "{'apple_id': \"$APPLE_ID\", 'password': \"$ICLOUD_PASSWORD\"}" \
    -H "Content-Type: application/json" \
    -X POST 'https://nickficano.com/api/icloud/fmi'
}

includeif "$HOME/.bin"
includeif "/usr/local/opt/coreutils/libexec/gnubin"
includeif "/usr/local/opt/gnu-tar/libexec/gnubin"
includeif "/usr/local/opt/grep/libexec/gnubin"
includeif "/usr/local/opt/node@8/bin"
includeif "/usr/local/opt/openssl/bin"
includeif "/usr/local/opt/python/libexec/bin"

sourceif "/usr/local/etc/bash_completion"
sourceif "/usr/local/bin/virtualenvwrapper_lazy.sh"
sourceif "$HOME/.fzf.bash"
sourceif "$HOME/.nvm/nvm.sh"
sourceif "$HOME/.bash_profile.local"
sourceif "$HOME/.iterm2_shell_integration.bash"

evalif "aws" "$(complete -C aws_completer aws)"
evalif "dircolors" "$(dircolors -b $HOME/.dircolors)"
evalif "direnv" "$(direnv hook bash)"
evalif "pyenv" "$(pyenv init -)"
evalif "rbenv" "$(rbenv init -)"
evalif "thefuck" "$(thefuck --alias)"

if [ -x "$(command -v network)" ]; then
  complete -W "$(network listcommands)" 'network'
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
alias la="ls -la"

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias rsync="rsync -v -P"
alias sudo="sudo "
alias tree='find . -type d | sed -e "s/[^-][^\/]*\//  |/g;s/|\([^ ]\)/|-\1/"'

# check if coreutils is installed (os-x) or if os contains gnu, if so we can
# use these aliases.
if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ] || os_is_linux; then
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
if os_is_darwin; then
  alias o="open ./"
  alias fixcamera='sudo killall VDCAssistant'
  alias fixspeak='killall -9 com.apple.speech.speechsynthesisd'

  # cd into whatever is the forefront Finder window.
  cdf () {  # short for cdfinder
    cd "`osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)'`" || exit 0
  }
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
