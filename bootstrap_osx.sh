#!/bin/sh

# Based off of thoughtbot's labtop script; see:
# https://github.com/thoughtbot/laptop/blob/master/mac

info() {
    fmt="$1"; shift
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@"
}

set -e

pip_is_installed() {
    pip freeze | grep -v '^\-e' | cut -d = -f 1 | grep -Fqx "$1";
}

pip_install_or_upgrade() {
    # I don't have a compariable ``pip_is_upgradable`` method because if you
    # run virtualbox, which includes ``pyvbox`` pip's get upgradable packages
    # fails. Fuck Oracle.
    if pip_is_installed "$1"; then
        info "Upgrading $1 ..."
        pip install -qU "$1"
    else
        info "Installing $1 ..."
        pip install -q "$1"
    fi
}

brew_install_or_upgrade() {
    if brew_is_installed "$1"; then
        if brew_is_upgradable "$1"; then
            info "Upgrading %s ..." "$1"
            brew upgrade "$@"
        else
            info "Already using the latest version of %s. Skipping ..." "$1"
        fi
    else
        info "Installing %s ..." "$1"
        brew install "$@"
    fi
}

brew_is_installed() {
    name="$(brew_expand_alias "$1")"
    brew list -1 | grep -Fqx "$name"
}

brew_is_upgradable() {
    name="$(brew_expand_alias "$1")"
    ! brew outdated --quiet "$name" >/dev/null
}

brew_tap() {
  brew tap "$1" 2>/dev/null
}

brew_expand_alias() {
    brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_launchctl_restart() {
    name="$(brew_expand_alias "$1")"
    domain="homebrew.mxcl.$name"
    plist="$domain.plist"

    info "Restarting %s ..." "$1"
    mkdir -p "$HOME/Library/LaunchAgents"
    ln -sfv "/usr/local/opt/$name/$plist" "$HOME/Library/LaunchAgents"

    if launchctl list | grep -Fq "$domain"; then
        launchctl unload "$HOME/Library/LaunchAgents/$plist" >/dev/null
    fi
    launchctl load "$HOME/Library/LaunchAgents/$plist" >/dev/null
}

if ! command -v brew >/dev/null; then
    info "Installing Homebrew ..."
    curl -fsS \
         'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    export PATH="/usr/local/bin:$PATH"
else
    info "Homebrew already installed. Skipping ..."
fi

info "Updating Homebrew formulas ..."
brew update

brew_install_or_upgrade 'aspell'
brew_install_or_upgrade 'autoconf'
brew_install_or_upgrade 'automake'
brew_install_or_upgrade 'bash-completion'
brew_install_or_upgrade 'coreutils'
brew_install_or_upgrade 'git'
brew_install_or_upgrade 'git-lfs'
brew_install_or_upgrade 'hub'
brew_install_or_upgrade 'htop'
brew_install_or_upgrade 'libyaml'
brew_install_or_upgrade 'nmap'
brew_install_or_upgrade 'node'
brew_install_or_upgrade 'nodejs'
brew_install_or_upgrade 'npm'
brew_install_or_upgrade 'reattach-to-user-namespace'
brew_install_or_upgrade 'redis'
brew_install_or_upgrade 'shellcheck'
brew_install_or_upgrade 'the_silver_searcher'
brew_install_or_upgrade 'tmux'
brew_install_or_upgrade 'wget'
brew_install_or_upgrade 'thefuck'
brew_install_or_upgrade 'watchman'
brew_install_or_upgrade 'opencv3'
brew_install_or_upgrade 'jq'
brew_install_or_upgrade 'pandoc'

brew_install_or_upgrade 'bash'
brew unlink bash
brew link --overwrite bash

# python stuff
brew_install_or_upgrade 'python3'
brew install python --framework
brew unlink python
brew link python --force

pip_install_or_upgrade "pipenv"
pip_install_or_upgrade "virtualenv"
pip_install_or_upgrade "virtualenvwrapper"

# we want these to be in the global site-packages
pip_install_or_upgrade "ipython"
pip_install_or_upgrade "requests"
pip_install_or_upgrade "flake8"
pip_install_or_upgrade "pep8"

# openssl
brew_install_or_upgrade 'openssl'
brew unlink openssl
brew link openssl --force

# imaging
brew_install_or_upgrade 'imagemagick'

# media
brew_install_or_upgrade 'ffmpeg'
brew reinstall ffmpeg --with-faac

brew_install_or_upgrade 'ssh-copy-id'

# brew_tap 'railwaycat/emacsmacport'
# brew_install_or_upgrade 'emacs-mac'
# brew unlink emacs-mac
# brew link emacs-mac --force

brew tap sudar/arduino-mk
brew install arduino-mk
