#!/bin/bash

if [[ $- != *i* ]] ; then
  return
fi

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
  if is_installed $1; then
    eval "$($2)"
  fi
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

is_installed () {
  command -v "$1" > /dev/null
}

is_darwin () {
  [[ $(uname -s) == "Darwin" ]]
}

is_linux () {
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

evalif "aws" "complete -C aws_completer aws"
evalif "direnv" "direnv hook bash"
evalif "pyenv" "pyenv init -"
evalif "rbenv" "rbenv init -"
evalif "thefuck" "thefuck --alias"
silence evalif "dircolors" "dircolors -b $HOME/.dircolors"

complete -cf sudo  # tab completions for sudo

export EDITOR='nano'
export VISUAL='atom'

export TERM=xterm-256color

export PS1="\h \[\e[1;32m\]\w\[\e[0m\] [\A] > "

export DOTFILES_VERSION='2.0.1'

# highlighting inside manpages and elsewhere
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underlin

export MANPAGER="less -X"               # don’t clear screen after quitting man
export GREP_COLOR='1;32'                # make match highlight color green
export DIRENV_LOG_FORMAT=               # stfu direnv
export WORKON_HOME=$HOME/.virtualenvs
export PYTHONDONTWRITEBYTECODE=true

export NODE_REPL_HISTORY=$HOME/.node_history  # persistent node REPL history
export NODE_REPL_HISTORY_SIZE='32768'         # allow 32³ entries
export NODE_REPL_MODE='sloppy'                # allow non-strict mode code

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:c:[ \t]*"

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'
alias d='cd ~/Desktop'
alias r='cd ~/Repos'
alias c='clear'
alias g='git'
alias cp='cp -i'
alias l='ls'
alias sl='ls'
alias la='ll -la'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rsync='rsync -v -P'
alias sudo='sudo '
alias vmk='mkvirtualenv'
alias vrm='rmvirtualenv'
alias vcd='cdvirtualenv'
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias reload='exec ${SHELL} -l'
alias map='xargs -n1'

is_darwin && alias o='open ./'
is_darwin && alias fixcamera='sudo killall VDCAssistant'
is_darwin && alias finder='cd "$(eval fpwd)" || exit 0'
is_linux || is_installed "gls" && alias ls='ls --color=auto -gXF --file-type'
is_linux || is_installed "gls" && alias ll='ls --color=auto -algX'

is_installed 'rlwrap' && alias node="env NODE_NO_READLINE=1 rlwrap node"
is_installed "bat" && alias cat="bat --paging never"
is_installed "network" && complete -W "$(network listcommands)" 'network'
is_installed "dotfiles" && complete -W "$(dotfiles -listcommands)" 'dotfiles'

setup_ssh
