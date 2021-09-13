#!/usr/bin/env bash

if [[ $- != *i* ]]; then
    return
fi

silence() {
    "$@" 2>/dev/null >/dev/null
}

ifshopt() {
    is_installed "shopt" && shopt -s "$1"
}

includeif() {
    [[ -d "$1" ]] && PATH="$1:${PATH}"
}

sourceif() {
    # shellcheck source=/dev/null
    [[ -f "$1" ]] && source "$1"
}

evalif() {
    is_installed "$1" && eval "$($2)"
}

abbr_pwd() {
    cwd=$(pwd | perl -F/ -ane 'print join( "/", map { $i++ < @F - 1 ?  substr $_,0,1 : $_ } @F)')
    echo -n "$cwd"
}

is_installed() {
    command -v "$1" > /dev/null
}

is_darwin() {
    [[ $(uname -s) == "Darwin" ]]
}

is_linux() {
    [[ $(uname -s) == "Linux" ]]
}

exists() {
    [[ -f "$1" ]]
}

is_ssh_agent_running() {
    pgrep -u "$USER" ssh-agent
}

setup_ssh() {
    if ! is_ssh_agent_running > /dev/null; then
        ssh-agent > "$HOME/.ssh-agent"
    fi

    if [[ "$SSH_AGENT_PID" == "" ]]; then
        eval "$(<"$HOME"/.ssh-agent)" > /dev/null
    fi

    # if empty keylist, add keys permanently
    if ! ssh-add -l > /dev/null; then
        ssh-add -k
    fi
}

homebrew_prefix() {
    if exists "/opt/homebrew/bin/brew"; then
        echo "/opt/homebrew"
    elif exists "/usr/local/bin/brew"; then
        echo "/usr/local"
    fi
}

export VISUAL="code --wait"
export EDITOR="$VISUAL"
export TERM=xterm-256color
# shellcheck disable=SC2155
export GPG_TTY="$(tty)"
export PS1="\h \[\e[1;32m\]\$(abbr_pwd)\[\e[0m\] [\A] > "
export DOTFILES_VERSION='3.10.2'
export BASH_SILENCE_DEPRECATION_WARNING=true

# highlighting inside manpages and elsewhere
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underlin

export MANPAGER="less -X" # don’t clear screen after quitting man
export GREP_COLOR='1;32'  # make match highlight color green
export DIRENV_LOG_FORMAT= # stfu direnv

# Python Devlopment Environment
export WORKON_HOME=$HOME/.virtualenvs
export PYTHONDONTWRITEBYTECODE=true
export PYENV_ROOT=$HOME/.pyenv
export POETRY_VIRTUALENVS_PATH=$HOME/.virtualenvs

export HISTCONTROL=ignoredups:erasedups:ignoreboth
export HISTFILESIZE=-1
export HISTSIZE=-1

# shellcheck disable=SC2155
export HOMEBREW_PREFIX="$(homebrew_prefix)"

export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew";
export HOMEBREW_SHELLENV_PREFIX="$HOMEBREW_PREFIX";
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}";

export NVM_DIR=$HOMEBREW_PREFIX/Cellar/nvm
export NODE_REPL_HISTORY=$HOME/.node_history # persistent node REPL history
export NODE_REPL_HISTORY_SIZE=32768        # allow 32³ entries
export NODE_REPL_MODE=sloppy               # allow non-strict mode code

# Save and reload the history after each command finishes
export SHELL_SESSION_HISTORY=0
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

ifshopt "nocaseglob"              # case-insensitive path expansion
ifshopt "checkwinsize"            # update window size after each command
ifshopt "histappend"              # append history instead of rewriting
ifshopt "hostcomplete"            # tab-completion of hostnames
ifshopt "cdspell"                 # autocorrect typos in path names
ifshopt "cmdhist"                 # save multi-line commands as one command
ifshopt "no_empty_cmd_completion" # no tab-complete if line is empty

includeif "$HOME/.bin"

# Prefer GNU Utilities instead of FeeeBSD When Available
includeif "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/gnu-getopt/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/gnu-time/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/gnu-which/libexec/gnubin"
includeif "$HOMEBREW_PREFIX/opt/grep/libexec/gnubin"

includeif "$HOMEBREW_PREFIX/opt/icu4c/bin"
includeif "$HOMEBREW_PREFIX/opt/icu4c/sbin"
includeif "$HOMEBREW_PREFIX/opt/openssl/bin"
includeif "$HOMEBREW_PREFIX/opt/openjdk/bin"
includeif "$HOMEBREW_PREFIX/opt/e2fsprogs/bin"
includeif "$HOMEBREW_PREFIX/opt/e2fsprogs/sbin"
includeif "$HOMEBREW_PREFIX/bin"
includeif "$HOMEBREW_PREFIX/sbin"

sourceif "$HOME/.bash_profile.local"
sourceif "$HOMEBREW_PREFIX/bin/virtualenvwrapper_lazy.sh"
sourceif "$HOMEBREW_PREFIX/opt/bash-completion/etc/bash_completion"
sourceif "$HOMEBREW_PREFIX/opt/git-extras/share/git-extras/git-extras-completion.sh"
sourceif "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"


evalif "aws" "complete -C aws_completer aws"
evalif "direnv" "direnv hook bash"
evalif "pyenv" "pyenv init -"
evalif "rbenv" "rbenv init -"
silence evalif "dircolors" "dircolors -b $HOME/.dircolors"

complete -cf sudo # tab completions for sudo

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
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias map='xargs -n1'
alias hgrep='history | egrep '

is_darwin && alias o='open ./'
is_darwin && alias f='cd "$(eval fpwd)" || exit 0'
is_darwin && sourceif "$HOME/.iterm2_shell_integration.bash"
is_darwin || is_installed 'code' && includeif "/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin"
is_linux || is_installed 'gls' && alias ls='ls --color=auto -gXF'
is_linux || is_installed 'gls' && alias ll='ls --color=auto -algX'

is_installed 'rlwrap' && alias node="env NODE_NO_READLINE=1 rlwrap node"
is_installed 'bat' && alias cat="bat --style=\"plain\" --paging never"
is_installed 'network' && complete -W "$(network listcommands)" 'network'
is_installed 'dotfiles' && complete -W "$(dotfiles -listcommands)" 'dotfiles'
setup_ssh
