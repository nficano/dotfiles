#!/usr/bin/env bash

# Terminate for non-interactive sessions.
case $- in
*i*) ;;
*) return ;; esac

text.substr() {
    echo "${1:$2:$3}"
}

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
    os.setenv "PS1" "\h \[\e[1;32m\]\$(shell.iterm2_style_path)\[\e[0m\] [\A] > "
}

shell.iterm2_style_path() {
    # Mimic iTerm2's absolute path abbreviation. For example,
    # "/usr/local/bin" abbreviates to "/u/l/bin".

    IFS="/"
    # Split path into array of directories. For example, ["usr", "local", "bin"].
    read -ra relpath <<<"$(dirs +0)"
    buffer=""
    dirname=$((${#relpath[*]} - 1)) # The working directory (e.g., "bin").

    # Append the first character of each directory name in `relpath` to buffer.
    for folder_name in "${relpath[@]}"; do
        # Do not abbreviate the working directory in the path.
        if [[ $folder_name != "${relpath[$dirname]}" ]]; then
            buffer+="$(text.substr "$folder_name" 0 1)/"
        fi
    done
    echo -n "$buffer${folder_name}"
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
os.setenv "DOTFILES_VERSION" "4.2.0"
os.setenv "DIRENV_LOG_FORMAT" ""

# Python Shell Environment
os.setenv "POETRY_VIRTUALENVS_PATH" "$HOME/.virtualenvs"
os.setenv "PYENV_ROOT" "$HOME/.pyenv"
os.setenv "PYTHONDONTWRITEBYTECODE" true
os.setenv "WORKON_HOME" "$HOME/.virtualenvs"

# Homebrew Shell Environment
os.setenv "HOMEBREW_PREFIX" "$(brew.prefix)"
os.setenv "HOMEBREW_CASKROOM" "$HOMEBREW_PREFIX/Caskroom"
os.setenv "HOMEBREW_CELLAR" "$HOMEBREW_PREFIX/Cellar"
os.setenv "HOMEBREW_REPOSITORY" "$HOMEBREW_PREFIX/Homebrew"
os.setenv "HOMEBREW_SHELLENV_PREFIX" "$HOMEBREW_PREFIX"
os.setenv "MANPATH" "$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
os.setenv "INFOPATH" "$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
os.setenv "HOMEBREW_NO_ENV_HINTS" 1
os.setenv "ARCHFLAGS" "-arch $(uname -m)"

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
shell.setopt "cdspell"      # directory name auto-correct during cd.
shell.setopt "checkwinsize" # Update window size after each command.
shell.setopt "cmdhist"      # Save multi-line commands as one.
shell.setopt "histappend"   # Append command history instead of
# clobbering.
shell.setopt "hostcomplete"            # tab-complete hostnames.
shell.setopt "no_empty_cmd_completion" # Do not suggest empty commands
# during tab completion.
shell.setopt "nocaseglob" # Case-insensitive path expansion.
shell.setopt "dirspell"   # Automatic spell-correct during
# tab completion.
shell.setopt "autocd"     # Change directory without typing cd.
shell.setopt "histverify" # !$ does not execute automatically.

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
sys.path.prepend "$HOMEBREW_PREFIX/opt/whois/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/icu4c/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/icu4c/sbin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/openssl/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/openjdk/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/e2fsprogs/bin"
sys.path.prepend "$HOMEBREW_PREFIX/opt/e2fsprogs/sbin"
sys.path.prepend "$HOMEBREW_PREFIX/bin"
sys.path.prepend "$HOMEBREW_PREFIX/sbin"
sys.path.prepend "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.bash.inc"
sys.path.prepend "/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin"
sys.path.prepend "$HOME/.local/bin"
sys.path.prepend "$HOME/.docker/bin"

shell.import "$HOMEBREW_PREFIX/bin/virtualenvwrapper_lazy.sh"
shell.import "$HOME/.config/op/plugins.sh"
shell.import "$HOMEBREW_PREFIX/opt/bash-completion/etc/bash_completion"
shell.import "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.bash.inc"
shell.import "$HOMEBREW_PREFIX/opt/git-extras/share/git-extras/git-extras-completion.sh"
shell.import "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
shell.import "$HOME/.iterm2_shell_integration.bash"
shell.import "$HOMEBREW_CASKROOM/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
shell.import "$HOME/.docker/init-bash.sh"
shell.import "$HOME/.pyenv/bin"
# Untracked Private Overrides (DO NOT SORT)
shell.import "$HOME/.bash_profile.local"

# Use "most" for Manpages when available, otherwise use "less".
sys.path.contains "most" && os.setenv "MANPAGER" "most"

# Use "vscode" for text editing when available, otherwise use "nano".
sys.path.contains "code" && os.setenv "VISUAL" "code"
sys.path.contains "code" && os.setenv "EDITOR" "code"
sys.path.contains "ngrok" && shell.eval "ngrok completion"
sys.path.contains "aws" && shell.eval "complete -C aws_completer aws"
sys.path.contains "direnv" && shell.eval "direnv hook bash"
sys.path.contains "pyenv" && shell.eval "pyenv init -"
sys.path.contains "pyenv" && shell.eval "pyenv virtualenv-init -"
sys.path.contains "rbenv" && shell.eval "rbenv init -"
sys.path.contains "dircolors" && shell.eval "dircolors -b $HOME/.dircolors"
# sys.path.contains "conda" && shell.eval "conda shell.bash hook"

complete -cf sudo # enable sudo tab-complete

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~/Desktop"
alias ~~="cd ~/"
alias -- -="cd -"
alias r="cd ~/Repos"
alias c="clear"
alias code="code-insiders"
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

source /Users/nficano/.docker/init-bash.sh || true # Added by Docker Desktop
