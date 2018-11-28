#!/bin/sh
set -e

# Based off of thoughtbot's labtop script; see:
# https://github.com/thoughtbot/laptop/blob/master/mac
HOMEBREW_PREFIX="/usr/local"

info() {
    fmt="$1"; shift
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@"
}

# Install Xcode Command Line Tools
if ! xcode-select -p > /dev/null; then
  xcode-select --install > /dev/null

  # Wait until the Xcode Command Line Tools are installed
  until xcode-select -p > /dev/null; do
    sleep 5
  done
fi

# Accept the Xcode/iOS license agreement
if ! sudo xcodebuild -license status; then
  sudo xcodebuild -license accept
fi

if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

setup_launch_agent () {
  if ! launchctl list | grep -Eiq 'org.nficano.dotfiles.DropboxSync.plist'; then
    info "Loading DropboxSync launchd script ..."
    root="$(git rev-parse --show-toplevel)"
    src="$root/LaunchAgents/org.nficano.dotfiles.DropboxSync.plist"
    dst="$HOME/Library/LaunchAgents/org.nficano.dotfiles.DropboxSync.plist"

    ln -s $src $dst
    launchctl load $dst
  fi
}

pip_is_installed () {
    pip freeze | grep -v '^\-e' | cut -d = -f 1 | grep -Fqx "$1";
}

pip_install_or_upgrade () {
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


brew_cask_install_or_upgrade () {
  if brew_cask_is_installed "$1"; then
    if brew_cask_is_upgradable "$1"; then
      info "Upgrading %s ..." "$1"
      brew cask upgrade "$@"
    else
      info "Already using the latest version of %s. Skipping ..." "$1"
    fi
  elif is_application_installed "$1"; then
    info "Unable to upgrade %s. Installed outside Cask. Skipping ..." "$1"
  else
    info "Installing %s ..." "$1"
    brew cask install "$@"
  fi
}

is_application_installed () {
  name="$(brew_cask_expand_artifacts "$1")"
  ls /Applications/ | grep -qi "$name" > /dev/null;
}

brew_cask_is_installed () {
  brew cask list | grep -qi "$1">/dev/null;
}

brew_install_or_upgrade () {
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

brew_cask_is_upgradable() {
    ! brew cask outdated --quiet "$1" >/dev/null
}

brew_tap() {
  brew tap "$1" 2>/dev/null
}

brew_cask_expand_artifacts() {
  brew cask info "$1" 2>/dev/null | tail -1 | grep -o '^.*.app'
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
brew_install_or_upgrade 'awscli'
brew_install_or_upgrade 'bash-completion'
brew_install_or_upgrade 'cmake'
brew_install_or_upgrade 'coreutils'
brew_install_or_upgrade 'direnv'
brew_install_or_upgrade 'eigen'
brew_install_or_upgrade 'fzf'
brew_install_or_upgrade 'ghostscript'
brew_install_or_upgrade 'git-lfs'
brew_install_or_upgrade 'git'
brew_install_or_upgrade 'guetzli'
brew_install_or_upgrade 'htop'
brew_install_or_upgrade 'httpie'
brew_install_or_upgrade 'hub'
brew_install_or_upgrade 'jpeg'
brew_install_or_upgrade 'jq'
brew_install_or_upgrade 'libpng'
brew_install_or_upgrade 'libtiff'
brew_install_or_upgrade 'libyaml'
brew_install_or_upgrade 'nmap'
brew_install_or_upgrade 'node@8'
brew_install_or_upgrade 'nodejs'
brew_install_or_upgrade 'npm'
brew_install_or_upgrade 'openexr'
brew_install_or_upgrade 'openssh'
brew_install_or_upgrade 'pandoc'
brew_install_or_upgrade 'pkg-config'
brew_install_or_upgrade 'reattach-to-user-namespace'
brew_install_or_upgrade 'redis'
brew_install_or_upgrade 'shellcheck'
brew_install_or_upgrade 'ssh-copy-id'
brew_install_or_upgrade 'tbb'
brew_install_or_upgrade 'the_silver_searcher'
brew_install_or_upgrade 'thefuck'
brew_install_or_upgrade 'tmux'
brew_install_or_upgrade 'unison'
brew_install_or_upgrade 'watchman'
brew_install_or_upgrade 'wget'
brew_install_or_upgrade 'yarn'
brew link --overwrite --force yarn

# shell
brew_install_or_upgrade 'bash'
brew unlink bash
brew link --overwrite --force bash

# python stuff
brew_install_or_upgrade 'python'
brew_install_or_upgrade 'python3'
brew install python --framework
brew unlink python
brew link --overwrite --force python

brew_install_or_upgrade 'pipenv'
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
brew link openssl --overwrite --force

# imaging
brew_install_or_upgrade 'imagemagick'

# media
brew_install_or_upgrade 'ffmpeg'
brew reinstall ffmpeg

# arduino
brew_tap 'sudar/arduino-mk'
brew_install_or_upgrade 'arduino-mk'

# cask
brew_tap caskroom/cask

# quicklook plugins
brew_cask_install_or_upgrade 'qlcolorcode'
brew_cask_install_or_upgrade 'qlstephen'
brew_cask_install_or_upgrade 'qlmarkdown'
brew_cask_install_or_upgrade 'quicklook-json'
brew_cask_install_or_upgrade 'qlimagesize'
brew_cask_install_or_upgrade 'webpquicklook'
brew_cask_install_or_upgrade 'suspicious-package'
brew_cask_install_or_upgrade 'quicklookase'
brew_cask_install_or_upgrade 'qlvideo'

brew_cask_install_or_upgrade '1password'
brew_cask_install_or_upgrade 'atom'
brew_cask_install_or_upgrade 'caskroom/versions/iterm2-beta'
brew_cask_install_or_upgrade 'docker'
brew_cask_install_or_upgrade 'dropbox'
brew_cask_install_or_upgrade 'fantastical'
brew_cask_install_or_upgrade 'firefox'
brew_cask_install_or_upgrade 'grammarly'
brew_cask_install_or_upgrade 'imagealpha'
brew_cask_install_or_upgrade 'imageoptim'
brew_cask_install_or_upgrade 'insomnia'
brew_cask_install_or_upgrade 'macdown'
brew_cask_install_or_upgrade 'microsoft-office'
brew_cask_install_or_upgrade 'mysqlworkbench'
brew_cask_install_or_upgrade 'ngrok'
brew_cask_install_or_upgrade 'notion'
brew_cask_install_or_upgrade 'purevpn'
brew_cask_install_or_upgrade 'sketch'
brew_cask_install_or_upgrade 'slack'
brew_cask_install_or_upgrade 'spotify'
brew_cask_install_or_upgrade 'the-unarchiver'
brew_cask_install_or_upgrade 'transmission'
brew_cask_install_or_upgrade 'vlc'
brew_cask_install_or_upgrade 'wireshark'
brew_cask_install_or_upgrade 'zoomus'
setup_launch_agent
