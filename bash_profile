#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Tab completions for sudo
complete -cf sudo

# Bash tab completions
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    # shellcheck disable=SC1091
    . /etc/bash_completion
fi

if [ -f /etc/git-completion ]; then
    # shellcheck disable=SC1091
    . /etc/git-completion
fi

if [ -f /opt/local/etc/profile.d/bash_completion.sh ]; then
    # shellcheck disable=SC1091
    . /opt/local/etc/profile.d/bash_completion.sh
fi

if [ -f /opt/local/etc/bash_completion ]; then
    # shellcheck disable=SC1091
    . /opt/local/etc/bash_completion
fi

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Check the window size after each command and, if necessary, update the values
# of LINES and COLUMNS.
shopt -s checkwinsize

# Append to the Bash history file, rather than overwriting it. Keep your
# terminal history persistent across multiple windows/tabs.
shopt -s histappend

# tab-completion of hostnames after @
shopt -s hostcomplete

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# =========
# functions
# =========
function silence() {
    "$@" 2> /dev/null > /dev/null;
}

function setup_ssh() {
    SSH_DIR="$HOME/.ssh"
    # if not started, start ssh-agent.
    if ! silence pgrep 'ssh-agent'; then
        silence ssh-agent
    fi

    # add keys if ssh directory exists.
    if [ -d "$SSH_DIR" ]; then
        find "$SSH_DIR" -name '*\.pem' | silence xargs ssh-add
    fi
}

function vpause() {
    # pause all running virtual boxes.
    VBoxManage list vms | grep "$1" | cut -d' ' -f1 | tr -d '"\n ' | xargs -0 -I BOX VBoxManage controlvm BOX pause
}

function vresume() {
    # resume all running virtual boxes.
    VBoxManage list vms | grep "$1" | cut -d' ' -f1 | tr -d '"\n ' | xargs -0 -I BOX VBoxManage controlvm BOX resume
}

function vrunning() {
    # get how many virtual boxes are running.
    VBoxManage list runningvms | grep "$1" | cut -d' ' -f1  | tr -d '"\n ' | wc -w | tr -d ' '
}

# ======
# colour
# ======

LS_COLORS='';

# directory colours
LS_COLORS=$LS_COLORS:'di=01;34'

# writable file colours
LS_COLORS=$LS_COLORS:'ow=01;34'

# symlink colours
LS_COLORS=$LS_COLORS:'ln=01;32'

# archive colours
LS_COLORS=$LS_COLORS:'*.tar=1;31'
LS_COLORS=$LS_COLORS:'*.tgz=1;31'
LS_COLORS=$LS_COLORS:'*.gz=1;31'
LS_COLORS=$LS_COLORS:'*.zip=1;31'
LS_COLORS=$LS_COLORS:'*.sit=1;31'
LS_COLORS=$LS_COLORS:'*.lha=1;31'
LS_COLORS=$LS_COLORS:'*.lzh=1;31'
LS_COLORS=$LS_COLORS:'*.arj=1;31'
LS_COLORS=$LS_COLORS:'*.bz2=1;31'
LS_COLORS=$LS_COLORS:'*.7z=1;31'
LS_COLORS=$LS_COLORS:'*.Z=1;31'
LS_COLORS=$LS_COLORS:'*.rar=1;31'

# backup colours
LS_COLORS=$LS_COLORS:'*.swp=1;30'
LS_COLORS=$LS_COLORS:'*.bak=1;30'
LS_COLORS=$LS_COLORS:'*~=1;30'

# python colours
LS_COLORS=$LS_COLORS:'*.py=01;33'
LS_COLORS=$LS_COLORS:'*.pyc=1;37'
LS_COLORS=$LS_COLORS:'*__init__.py=1;36'

# makefile colour
LS_COLORS=$LS_COLORS:'*Makefile=4;1;33'

# readme colour
LS_COLORS=$LS_COLORS:'*README=4;1;33'

# install colour
LS_COLORS=$LS_COLORS:'*INSTALL=4;1;33'

export LS_COLORS

# enable support for colour coding your files/directories/symlinks.
export CLICOLOR=true

# tell pip to automatically use the currently active virtualenv.
export PIP_RESPECT_VIRTUALENV=true

# when using virtualenvwrapper, tell pip to automatically create its
# virtualenvs in ``$WORKON_HOME``.
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export WORKON_HOME=$HOME/.virtualenvs

# don't create .pyc files.
export PYTHONDONTWRITEBYTECODE=true

# tell virtualenvwrapper which python to use.
export VIRTUALENVWRAPPER_PYTHON=`which python`

# tell virtualenv to use Distribute instead of setuptools.
export VIRTUALENV_DISTRIBUTE=true

# enable 256-bit colours.
export TERM=xterm-256color

# no duplicate entries.
export HISTCONTROL=ignoredups:erasedups

# save a lot of history.
export HISTSIZE=100000
export HISTFILESIZE=100000

# after each command, save and reload history.
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# don’t clear the screen after quitting a manual page.
export MANPAGER="less -X"

# colour value set to green.
export GREP_COLOR='1;32'
export PATH="/opt/local/bin:/opt/local/sbin:/opt/local/libexec/gnubin/:$PATH"

# =======
# aliases
# =======

# navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# permissions
alias 640='chmod 640'  # -rw-   r--    ---
alias 644='chmod 644'  # -rw-   r--    r--
alias 755='chmod 755'  # -rwx   r-x    r-x
alias 775='chmod 775'  # -rwx   rwx    r-x

# places
alias d="cd ~/Desktop"
alias dl="cd ~/Downloads"
alias p="cd ~/Projects"
alias r="cd ~/Repos"

alias c="clear"
alias e="exit"
alias g="git"
alias h="history"

# make sure ls is the GNU version as some switches used aren't available in the
# BSD version.
if ls --version | silence grep "coreutils"; then
    alias lk='ls -lSr'
    alias ll="ls --human-readable --almost-all -l"
    alias lm='ls -al | more'
    alias ls="ls --color=auto --group-directories-first -X --classify -G"
    alias lx="ls -lXB"
fi

alias l="ls"
alias sl="ls"
alias la="ls -a"
alias sudo="sudo "
alias tree='find . -type d | sed -e "s/[^-][^\/]*\//  |/g;s/|\([^ ]\)/|-\1/"'

# emacs :)
if [ -x "$(command -v emacs)" ]; then
    alias e='emacs'
    alias ec='emacsclient'
fi

# virtualenv
if [ -x "$(command -v mkvirtualenv)" ]; then
    alias vmk='mkvirtualenv'
    alias vrm='rmvirtualenv'
fi

# make grep colorful by default.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# networking
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias openports="sudo lsof -Pan -i tcp -i udp | grep -i 'listen'"
alias rsync="rsync -v -P"

# os-x specific
if [[ $OSTYPE =~ darwin ]]; then
    alias o="open ./"
    alias dnsflush="dscacheutil -flushcache"

    # macports
    if [ -x "$(command -v port)" ]; then
        alias portupdate="sudo port -v upgrade outdated"
    fi
fi

# mercurial
if [ -x "$(command -v nmap)" ]; then
    alias nmap="sudo nmap"
fi

# mercurial
if [ -x "$(command -v hg)" ]; then
    alias hM="hg commit -m 'Merged'"
    alias hadd="hg add ."
    alias hdiff="hg diff"
    alias hdiscard="hg update -C -r ."
    alias hl="hg log --no-merges -r: --stat"
    alias hm="hg merge"
    alias ho="hg out"
    alias hpu="hg pull -u"
    alias hs="hg status"
    alias hundo="hg revert -C --all"
fi

# git
if [ -x "$(command -v git)" ]; then
    alias ga='git add'
    alias gb='git branch'
    alias gc='git checkout'
    alias gd='git diff'
    alias gm='git commit -m'
    alias gma='git commit -am'
    alias gp='git push'
    alias gpu='git pull'
    alias gs='git status'
fi

if [ -n "$SSH_CLIENT" ]; then
    # make hostname red if connected via ssh.
    hostname="\[\e[1;31m\]\h\[\e[0m\]"
else
    hostname="\h"
fi

export PS1="\u at ${hostname} \[\e[1;32m\]\w\[\e[0m\] "
unset hostname

if [ -f "$HOME/.bash_profile.local" ]; then
    . "$HOME/.bash_profile.local"
fi

setup_ssh
