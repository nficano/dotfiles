#!/bin/bash

DEST_DIR="$HOME/Dropbox/$HOSTNAME Home"

info() {
    fmt="$1"; shift
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@"
}


unison_sync() {
  unison $1 "$DEST_DIR/$2" \
    -auto \
    -batch \
    -prefer $1 \
    -silent \
    -logfile /var/log/unison.log
}

info "Synchronizing Fonts..."
unison_sync "$HOME/Library/Fonts/" "Fonts/"

info "Synchronizing AWS credentials..."
unison_sync "$HOME/.aws/" "aws/"

info "Synchronizing ssh..."
unison_sync "$HOME/.ssh/" "ssh/"

info "Synchronizing bash history..."
unison_sync "$HOME/.bash_history" "bash_history"

info "Synchronizing bash_profile.local..."
unison_sync "$HOME/.bash_profile.local" "bash_profile.local"

info "Synchronizing Keychains..."
unison_sync "$HOME/Library/Keychains/" "Library/Keychains/"

info "Generating Brew Installs List..."
brew list > "$DEST_DIR/brew_installs.txt"

info "Generating Brew Cask Installs List..."
brew cask list > "$DEST_DIR/brewcask_installs.txt"

info "Generating MacOS App Installs List..."
find /Applications \
  -iname *.app \
  ! -iname "App Store.app" \
  ! -iname "Automator.app" \
  ! -iname "Backup and Sync.app" \
  ! -iname "Calculator.app" \
  ! -iname "Calendar.app" \
  ! -iname "Chess.app" \
  ! -iname "Contacts.app" \
  ! -iname "Dashboard.app" \
  ! -iname "Dictionary.app" \
  ! -iname "DVD Player.app" \
  ! -iname "FaceTime.app" \
  ! -iname "Font Book.app" \
  ! -iname "GarageBand.app" \
  ! -iname "iBooks.app" \
  ! -iname "Image Capture.app" \
  ! -iname "iMovie.app" \
  ! -iname "iTerm.app" \
  ! -iname "iTunes.app" \
  ! -iname "Keynote.app" \
  ! -iname "Launchpad.app" \
  ! -iname "Mail.app" \
  ! -iname "Maps.app" \
  ! -iname "Messages.app" \
  ! -iname "Mission Control.app" \
  ! -iname "Notes.app" \
  ! -iname "Numbers.app" \
  ! -iname "Pages.app" \
  ! -iname "Photo Booth.app" \
  ! -iname "Photos.app" \
  ! -iname "Preview.app" \
  ! -iname "QuickTime Player.app" \
  ! -iname "Reminders.app" \
  ! -iname "Safari.app" \
  ! -iname "Siri.app" \
  ! -iname "Stickies.app" \
  ! -iname "System Preferences.app" \
  ! -iname "TextEdit.app" \
  ! -iname "Time Machine.app" \
  -maxdepth 1 \
  -exec basename {} \; | sort \
  > "$DEST_DIR/osx_installs.txt"

info ""
info "✨  Done."
