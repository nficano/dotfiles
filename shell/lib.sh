#!/usr/bin/env bash

# Shared profile configuration sourced by both Bash and Zsh shells.
# Avoid re-running when sourced multiple times.
if [[ -n "${DOTFILES_PROFILE_COMMON:-}" ]]; then
  return
fi
DOTFILES_PROFILE_COMMON=1

# Detect operating system once so we can branch efficiently later.
__dotfiles_os="$(uname -s 2>/dev/null || true)"

dotfiles_is_darwin() {
  [[ "$__dotfiles_os" == "Darwin" ]]
}

dotfiles_is_linux() {
  [[ "$__dotfiles_os" == "Linux" ]]
}

dotfiles_has() {
  command -v "$1" >/dev/null 2>&1
}

dotfiles_path_prepend() {
  local dir="$1"
  [[ -z "$dir" || ! -d "$dir" ]] && return
  case ":$PATH:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
}

dotfiles_path_append() {
  local dir="$1"
  [[ -z "$dir" || ! -d "$dir" ]] && return
  case ":$PATH:" in
    *":${dir}:"*) ;;
    *) PATH="${PATH}:${dir}" ;;
  esac
}

dotfiles_path_prepend_many() {
  local dir
  for dir in "$@"; do
    dotfiles_path_prepend "$dir"
  done
}

dotfiles_path_append_many() {
  local dir
  for dir in "$@"; do
    dotfiles_path_append "$dir"
  done
}

dotfiles_configure_homebrew() {
  dotfiles_has brew || return
  local prefix
  prefix="$(brew --prefix 2>/dev/null || true)"
  [[ -z "$prefix" ]] && return

  export BREW_PREFIX="$prefix"
  export HOMEBREW_CASKROOM="$BREW_PREFIX/Caskroom"
  export HOMEBREW_CELLAR="$BREW_PREFIX/Cellar"
  export HOMEBREW_REPOSITORY="$BREW_PREFIX/Homebrew"
  export HOMEBREW_SHELLENV_PREFIX="$BREW_PREFIX"
  export HOMEBREW_NO_ENV_HINTS=1

  local manpath="$BREW_PREFIX/share/man"
  if [[ -d "$manpath" ]]; then
    if [[ -n "${MANPATH:-}" ]]; then
      export MANPATH="$manpath:$MANPATH"
    else
      export MANPATH="${manpath}:"
    fi
  fi

  local infopath="$BREW_PREFIX/share/info"
  if [[ -d "$infopath" ]]; then
    if [[ -n "${INFOPATH:-}" ]]; then
      export INFOPATH="$infopath:$INFOPATH"
    else
      export INFOPATH="$infopath"
    fi
  fi
}

dotfiles_setup_ls_aliases() {
  if dotfiles_is_linux; then
    alias ls='ls --color=auto -gXF'
    alias ll='ls --color=auto -algX'
  elif dotfiles_is_darwin && dotfiles_has gls; then
    alias ls='gls --color=auto -gXF'
    alias ll='gls --color=auto -algX'
  else
    alias ls='ls -GF'
    alias ll='ls -alG'
  fi
}

dotfiles_ensure_ssh_agent() {
  local env_file="$1"
  [[ -n "$env_file" ]] || return 1
  dotfiles_has ssh-agent || return 0
  dotfiles_has ssh-add || return 0

  dotfiles_has pgrep || return 0

  touch "$env_file"
  if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    rm -f "$env_file"
    if ssh-agent >/tmp/.dotfiles_ssh_agent.$$ 2>/dev/null; then
      sed 's/^echo/#echo/' /tmp/.dotfiles_ssh_agent.$$ >"$env_file"
      rm -f /tmp/.dotfiles_ssh_agent.$$
    else
      rm -f /tmp/.dotfiles_ssh_agent.$$ "$env_file"
      return 1
    fi
  fi

  # shellcheck disable=SC1090
  source "$env_file"

  if ! ssh-add -l >/dev/null 2>&1; then
    ssh-add -k >/dev/null 2>&1 || ssh-add >/dev/null 2>&1 || true
  fi
}

# ---------- Environment ----------
export TERM="xterm-256color"
if gpg_tty="$(tty 2>/dev/null)"; then
  export GPG_TTY="$gpg_tty"
fi
export DOTFILES_VERSION="4.2.0"
export DIRENV_LOG_FORMAT=""
export POETRY_VIRTUALENVS_PATH="$HOME/.virtualenvs"
export PYENV_ROOT="$HOME/.pyenv"
export PYTHONDONTWRITEBYTECODE=1
export WORKON_HOME="$HOME/.virtualenvs"

dotfiles_configure_homebrew
if [[ -n "${BREW_PREFIX:-}" ]]; then
  arch_value="$(uname -m 2>/dev/null || echo arm64)"
  export ARCHFLAGS="-arch ${arch_value}"
  export BASH_SILENCE_DEPRECATION_WARNING=1
fi
unset arch_value

export HSTR_CONFIG="hicolor"
export HSTR_TIOCSTI="y"

# ---------- Node.js ----------
export NODE_REPL_HISTORY="$HOME/.node_history"
export NODE_REPL_HISTORY_SIZE=32768
export NODE_REPL_MODE="sloppy"
export NVM_DIR="$HOME/.nvm"

# ---------- History ----------
export HISTCONTROL="ignoredups:erasedups:ignoreboth"
export HISTFILESIZE=-1
export HISTSIZE=-1
export SHELL_SESSION_HISTORY=0
export MANPAGER="${MANPAGER:-less}"
export VISUAL="${VISUAL:-nano}"
export EDITOR="${EDITOR:-nano}"
export LESS="-R"

# ---------- PATH ----------
dotfiles_path_prepend "$HOME/.bin"
if [[ -n "${BREW_PREFIX:-}" ]]; then
  dotfiles_path_prepend_many \
    "$BREW_PREFIX/opt/coreutils/libexec/gnubin" \
    "$BREW_PREFIX/opt/findutils/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-getopt/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-sed/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-tar/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-time/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-which/libexec/gnubin" \
    "$BREW_PREFIX/opt/grep/libexec/gnubin" \
    "$BREW_PREFIX/opt/whois/bin" \
    "$BREW_PREFIX/opt/icu4c/bin" \
    "$BREW_PREFIX/opt/icu4c/sbin" \
    "$BREW_PREFIX/opt/openssl/bin" \
    "$BREW_PREFIX/opt/openjdk/bin" \
    "$BREW_PREFIX/opt/e2fsprogs/bin" \
    "$BREW_PREFIX/opt/e2fsprogs/sbin" \
    "$BREW_PREFIX/bin" \
    "$BREW_PREFIX/sbin"
fi
dotfiles_path_prepend_many \
  "$HOME/.local/bin" \
  "$HOME/.docker/bin" \
  "$HOME/.pyenv/bin"
dotfiles_path_append "$HOME/Dropbox/.sbin"

# ---------- Aliases ----------
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
alias hh="hstr"
alias px2em="css-px-to-em"
+x() {
  # for zsh compat.
  file-mark-executable "$@"
}
# shellcheck disable=SC2139
alias "svgo*"="svg-optimize-all"
# shellcheck disable=SC2139
alias "webp*"="convert-to-webp"
# shellcheck disable=SC2139
alias "mp4*"="convert-to-mp4"
# shellcheck disable=SC2139
alias "fe*"="find-extension"
# shellcheck disable=SC2139
alias "fn*"="find-filename"
alias dots="bin-list-scripts"
alias resolve="path-resolve"
alias copy="path-copy-clipboard"
alias expand="path-expand-tilde"
alias showdesk="finder-show-desktop"
alias hidedesk="finder-hide-desktop"
alias ip="network-info"
alias add-alias="shell-add-alias"
alias typo="espanso-add-typo"
alias pid-on-port="network-pid-on-port"
alias listeners="network-listeners"
alias hgrep="history-grep"
alias headers="http-show-headers"
dotfiles_is_darwin && alias o="open ./"
dotfiles_is_darwin && alias f='cd "$(finder-front-path)" || exit 0'
dotfiles_setup_ls_aliases
dotfiles_has rlwrap && alias node='env NODE_NO_READLINE=1 rlwrap node'
dotfiles_has bat && alias cat='bat --style="plain" --paging never'

# ---------- Command helpers ----------
if dotfiles_has most; then
  export MANPAGER="most"
fi

if dotfiles_has cursor; then
  export VISUAL="cursor"
  export EDITOR="cursor"
fi

if [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/bin/virtualenvwrapper_lazy.sh" ]]; then
  # shellcheck disable=SC1090
  source "$BREW_PREFIX/bin/virtualenvwrapper_lazy.sh"
fi

if [[ -f "$HOME/.dircolors" ]] && dotfiles_has dircolors; then
  eval "$(dircolors -b "$HOME/.dircolors")"
fi

dotfiles_ensure_ssh_agent "$HOME/.ssh-agent.env"
