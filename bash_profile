#!/usr/bin/env bash

# Terminate non-interactive sessions.
case $- in
*i*) ;;
*) return ;; esac

os.devnull() {
    "$@" 2>/dev/null >/dev/null
}

os.setenv() {
    export "${1}"="${2}"
}

os.getenv() {
    env | grep "^$1=" | cut -d'=' -f2
}

os.platform.is_darwin() {
    [[ $(sys.platform) == darwin ]]
}

os.platform.is_linux() {
    [[ $(sys.platform) == linux ]]
}

os.path.exists() {
    [[ -f "$1" ]]
}

shell.setopt() {
    sys.path.contains "shopt" && shopt -s "$1"
}

shell.import() {
    # shellcheck source=/dev/null
    [[ -f "$1" ]] && source "$1"
}

shell.eval() {
    eval "$($1)"
}

shell.setup_prompt() {
    os.setenv "PS1" "\h \[\e[1;32m\]\$(shell.iterm2_style_cwd)\[\e[0m\] [\A] > "
}

shell.iterm2_style_cwd() {
    IFS="/" read -ra path <<< "$(dirs +0)"
    buffer=""
    working_dir=$(( ${#path[*]} - 1 ))

    for dirname in "${path[@]}"; do
        if [[ $dirname != "${path[$working_dir]}" ]]; then
            buffer+="${dirname:0:1}/"
        else
            buffer+="${dirname}"
        fi 
    done
    echo -n "$buffer"
}

sys.path.prepend() {
    [[ -d "$1" ]] && PATH="$1:${PATH}"
}

sys.path.contains() {
    os.devnull command -v "$1"
}

sys.platform() {
    uname -s | tr "[:upper:]" "[:lower:]"
}

ssh_agent.active_sessions() {
    pgrep -u "$USER" ssh-agent
}

ssh_agent.start() {
    # Start ssh-agent daemon and write environment variables to an env 
    # file to allow sharing a single instance between terminal sessions.
    os.devnull rm "$1"
    ssh-agent | sed "s/^echo/#echo/" >"$1"
    chmod 600 "$1"
    shell.import "$1"
}

ssh_agent.init() {
    env="$1"
    touch "$env"
    
    if ! os.devnull ssh_agent.active_sessions; then
        ssh_agent.start "$env"
    else
        shell.import "$env"
    fi

    if ! os.devnull ssh-add -l; then
        os.devnull ssh-add -k
    fi
}

brew.prefix() {
    # Resolve the Homebrew path on both Apple Silicon and Intel.
    if os.path.exists /opt/homebrew/bin/brew; then
        echo /opt/homebrew
    elif os.path.exists /usr/local/bin/brew; then
        echo /usr/local
    fi
}

os.setenv "TERM" "xterm-256color"
os.setenv "GPG_TTY" "$(tty)"
os.setenv "DOTFILES_VERSION" "4.0.2"
os.setenv "GREP_COLOR" "1;32" # make match highlight color green
os.setenv "DIRENV_LOG_FORMAT" ""

# Python Shell Environment
os.setenv "POETRY_VIRTUALENVS_PATH" "$HOME/.virtualenvs"
os.setenv "PYENV_ROOT" "$HOME/.pyenv"
os.setenv "PYTHONDONTWRITEBYTECODE" true
os.setenv "WORKON_HOME" "$HOME/.virtualenvs"

# Homebrew Shell Environment
os.setenv "HOMEBREW_PREFIX" "$(brew.prefix)"
os.setenv "HOMEBREW_CELLAR" "$HOMEBREW_PREFIX/Cellar"
os.setenv "HOMEBREW_REPOSITORY" "$HOMEBREW_PREFIX/Homebrew"
os.setenv "HOMEBREW_SHELLENV_PREFIX" "$HOMEBREW_PREFIX"
os.setenv "MANPATH" "$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
os.setenv "INFOPATH" "$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Node.js Environment
os.setenv "NODE_REPL_HISTORY" "$HOME/.node_history" # persistent REPL history
os.setenv "NODE_REPL_HISTORY_SIZE" 32768            # allow 32³ entries
os.setenv "NODE_REPL_MODE" "sloppy"                 # use non-strict mode code

# Shell Session Command History
os.setenv "HISTCONTROL" "ignoredups:erasedups:ignoreboth"
os.setenv "HISTFILESIZE" -1
os.setenv "HISTSIZE" -1

os.setenv "SHELL_SESSION_HISTORY" 0 # Save & reload history after each command
os.setenv "PROMPT_COMMAND" "history -a; history -c; history -r; $PROMPT_COMMAND"

os.setenv "MANPAGER" "less"
os.setenv "VISUAL" "nano"
os.setenv "EDITOR" "nano"

# Set various Bash options.
shell.setopt "nocaseglob"              # case-insensitive path expansion
shell.setopt "checkwinsize"            # update window size after each command
shell.setopt "histappend"              # append history instead of rewriting
shell.setopt "hostcomplete"            # tab-completion of hostnames
shell.setopt "cdspell"                 # autocorrect typos in path names
shell.setopt "cmdhist"                 # save multi-line commands as one command
shell.setopt "no_empty_cmd_completion" # no tab-complete if line is empty
shell.setopt "cdspell"                 # auto-correct mistyped directory names

# Untracked Shell Scripts (DO NOT SORT)
sys.path.prepend "$HOME/.bin"

# Prefer GNU Utilities instead of FeeeBSD When Available
sys.path.prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/gnu-getopt/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/gnu-time/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/gnu-which/libexec/gnubin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/grep/libexec/gnubin"

sys.path.prepend "$HOMEBREW_PREFIX/opt/icu4c/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/icu4c/sbin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/openssl/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/openjdk/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/e2fsprogs/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/e2fsprogs/sbin"
sys.path.prepend "$HOMEBREW_PREFIX/bin"
sys.path.prepend "$HOMEBREW_PREFIX/sbin"
sys.path.prepend "/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin"

shell.import "$HOMEBREW_PREFIX/bin/virtualenvwrapper_lazy.sh"
shell.import "$HOMEBREW_PREFIX/opt/bash-completion/etc/bash_completion"
shell.import "$HOMEBREW_PREFIX/opt/git-extras/share/git-extras/git-extras-completion.sh"
shell.import "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
shell.import "$HOME/.iterm2_shell_integration.bash"

# Untracked Private Overrides (DO NOT SORT)
shell.import "$HOME/.bash_profile.local"

# Use "most" for Manpages when available, otherwise use "less".
sys.path.contains "most" && os.setenv "MANPAGER" "most"

# Use "vscode" for text editing when available, otherwise use "nano".
sys.path.contains "code" && os.setenv "VISUAL" "code"
sys.path.contains "code" && os.setenv "EDITOR" "code"

sys.path.contains "aws" && shell.eval "complete -C aws_completer aws"
sys.path.contains "direnv" && shell.eval "direnv hook bash"
sys.path.contains "pyenv" && shell.eval "pyenv init -"
sys.path.contains "rbenv" && shell.eval "rbenv init -"
sys.path.contains "dircolors" && shell.eval "dircolors -b $HOME/.dircolors"

complete -cf sudo # enable sudo tab-complete

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"
alias d="cd ~/Desktop"
alias r="cd ~/Repos"
alias c="clear"
alias g="git"
alias cp="cp -i"
alias l="ls"
alias sl="ls"
alias la="ll -la"
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias rsync="rsync -v -P"
alias sudo="sudo "
alias ga="git add"
alias gd="git diff"
alias gs="git status"
alias map="xargs -n1"
alias hgrep="history | egrep "

# Create alias to open cwd in Finder.
os.platform.is_darwin && alias o="open ./"

# Create alias to cd to current working Finder directory.
os.platform.is_darwin && alias f='cd "$(eval fpwd)" || exit 0'
os.platform.is_linux || sys.path.contains "gls" && alias ls="ls --color=auto -gXF"
os.platform.is_linux || sys.path.contains "gls" && alias ll="ls --color=auto -algX"

sys.path.contains "rlwrap" && alias node="env NODE_NO_READLINE=1 rlwrap node"
sys.path.contains "bat" && alias cat="bat --style=\"plain\" --paging never"
sys.path.contains "network" && complete -W "$(network listcommands)" "network"
sys.path.contains "dotfiles" && complete -W "$(dotfiles -listcommands)" "dotfiles"


shell.setup_prompt
ssh_agent.init "$HOME/.ssh-agent.env"
