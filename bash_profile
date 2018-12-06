#!/bin/bash

# If not running ractively, don't do anything
[ -z "$PS1" ] && return

# Tab completions for sudo
complete -cf sudo
if [ -d "$HOME/.ssh/config.d/" ]; then
  complete -o default -o nospace -W "$(cat ~/.ssh/config.d/* | grep "^Host " | awk '{print $2}')" ssh scp
fi

if [ -x "$(command -v aws)" ]; then
    # Tab completions for awscli
    complete -C aws_completer aws
fi

if [ -x "$(command -v pyenv)" ]; then
  eval "$(pyenv init -)"
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
silence() {
    "$@" 2> /dev/null > /dev/null;
}

setup_ssh() {
    local SSH_DIR="$HOME/.ssh"
    # if not started, start ssh-agent.
    if ! silence pgrep 'ssh-agent'; then
        silence ssh-agent
    fi

    # add keys if ssh directory exists.
    if [ -d "$SSH_DIR" ]; then
        find "$SSH_DIR" -name '*\.pem' | silence xargs ssh-add
    fi
}

vpause() {
    # pause all running virtual boxes.
    VBoxManage list vms | grep "$1" | cut -d' ' -f1 | tr -d '"\n ' | xargs -0 -I BOX VBoxManage controlvm BOX pause
}

vresume() {
    # resume all running virtual boxes.
    VBoxManage list vms | grep "$1" | cut -d' ' -f1 | tr -d '"\n ' | xargs -0 -I BOX VBoxManage controlvm BOX resume
}

vrunning() {
    # get how many virtual boxes are running.
    VBoxManage list runningvms | grep "$1" | cut -d' ' -f1  | tr -d '"\n ' | wc -w | tr -d ' '
}

conditionally_prefix_path() {
    # make sure directory exists and prepend it to system path.
    local dir=$1
    if [ -d "$dir" ]; then
        PATH="$dir:${PATH}"
    fi
}

conditionally_source() {
    local src=$1
    if [ -f "$src" ]; then
        # shellcheck source=/dev/null
        source "$src"
    fi
}

path() {
    # pretty-print system path.
    echo "$PATH" | tr -s ':' '\n'
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

LS_COLORS=$LS_COLORS:'*.local=4;0;33'

export LS_COLORS

# enable support for colour coding your files/directories/symlinks.
export CLICOLOR=true

# colour value set to green.
export GREP_COLOR='1;32'

# colour for manpages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# tell pip to automatically use the currently active virtualenv.
export PIP_RESPECT_VIRTUALENV=true

# when using virtualenvwrapper, tell pip to automatically create its
# virtualenvs in ``$WORKON_HOME``.
export WORKON_HOME=$HOME/.virtualenvs

# don't create .pyc files.
export PYTHONDONTWRITEBYTECODE=true

# tell virtualenv to use Distribute instead of setuptools.
export VIRTUALENV_DISTRIBUTE=true

# enable 256-bit colours.
export TERM=xterm-256color

# no duplicate entries.
export HISTCONTROL=ignoredups:erasedups

# save a lot of history.
export HISTSIZE=100000
export HISTFILESIZE=100000

# we don't care to save these.
export HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:c:[ \t]*"

# after each command, save and reload history.
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# don’t clear the screen after quitting a manual page.
export MANPAGER="less -X"

# stfu direnv
export DIRENV_LOG_FORMAT=

# path
conditionally_prefix_path "$HOME/.bin"
conditionally_prefix_path "/usr/local/opt/grep/libexec/gnubin"
conditionally_prefix_path "/usr/local/opt/coreutils/libexec/gnubin"
conditionally_prefix_path "/usr/local/opt/openssl/bin"
conditionally_prefix_path "/usr/local/opt/python/libexec/bin"
conditionally_prefix_path "/usr/local/opt/node@8/bin"
# export PATH=.:./bin:${PATH}

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

# always ask before replacing
alias cp='cp -i'

# display every instance of the given command found in the path
# alias which='type -all'

alias l="ls"
alias sl="ls"
alias la="ls -a"

# check if coreutils is installed (os-x) or if os contains gnu, if so we can
# use these aliases.
if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ] || [[ $OSTYPE =~ gnu ]]; then
    alias lk='ls -lSr'
    alias ll="ls --human-readable --almost-all -l"
    alias lm='ls -al | more'
    alias ls="ls --color=auto --group-directories-first -X --classify -G"
    alias lx="ls -lXB"
fi

alias sudo="sudo "
alias tree='find . -type d | sed -e "s/[^-][^\/]*\//  |/g;s/|\([^ ]\)/|-\1/"'

# virtualenvwrapper
if [ -x "$(command -v virtualenvwrapper.sh)" ]; then
    alias vmk='mkvirtualenv'
    alias vrm='rmvirtualenv'
    alias vcd='cdvirtualenv'
fi

# make grep colorful by default.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias rsync="rsync -v -P"

# os-x specific
if [[ $OSTYPE =~ darwin ]]; then
    alias o="open ./"
    alias dnsflush="dscacheutil -flushcache"
    alias fixcamera='sudo killall VDCAssistant'
    alias fixspeak='killall -9 com.apple.speech.speechsynthesisd'
fi

if [ -x "$(command -v bat)" ]; then
  alias cat="bat --paging never"
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

#stupid github tool
if [ -x "$(command -v hub)" ]; then
    alias git='hub'
fi

export EDITOR='nano'
export VISUAL='atom'

if [ -n "$SSH_CLIENT" ]; then
    # make hostname red if connected via ssh.
    hostname="\[\e[1;31m\]\u@\h\[\e[0m\]"
else
    hostname="\h"
fi

export PS1="${hostname} \[\e[1;32m\]\w\[\e[0m\] [\A] > "
unset hostname

setup_ssh

conditionally_source "/usr/local/etc/bash_completion.d"
conditionally_source "/usr/local/bin/virtualenvwrapper_lazy.sh"
conditionally_source "$HOME/.fzf.bash"
conditionally_source "$HOME/.nvm/nvm.sh"
conditionally_source "$HOME/.bash_profile.local"
conditionally_source "$HOME/.iterm2_shell_integration.bash"

if [ -f "$HOME/.bash_completion.d/inet" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.bash_completion.d/inet"
fi

if [ -x "$(command -v brew)" ]; then
    conditionally_source "$(brew --prefix)/etc/bash_completion"
fi

if [ -x "$(command -v rbenv)" ]; then
  eval "$(rbenv init -)"
fi

if [ -x "$(command -v thefuck)" ]; then
  eval "$(thefuck --alias)"
fi

[ -x "$(command -v direnv)" ] && eval "$(direnv hook bash)"
! [[ "$PROMPT_COMMAND" =~ _direnv_hook ]] && PROMPT_COMMAND="_direnv_hook;$PROMPT_COMMAND";
