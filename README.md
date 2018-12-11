<p align="center">
  <img src="https://s3.amazonaws.com/nf-assets/dotfiles-logo.svg" alt="dotfiles" width="474" height="148">
</p>

## Nick Ficano's dotfiles

This repo contains my dotfiles, the scripts to bootstrap my Mac OS environment,
and various utilities that have no other home.

While I will outline how to install my configuration from scratch, I would
recommend using it for reference purposes only.

## Structure

- ``bin/`` - all of my custom executable scripts.
- ``misc/`` - stuff that doesn't have a home.
- ``rc.d/`` - config files that I symlink to my home directory.

## Highlights

- ``bin/dropbox-sync`` - syncronizes frequently updated files to dropbox.
- ``bin/findmyiphone`` - triggers "Find My iPhone" from command-line.
- ``bin/lan-doctor`` - detects and automatically fixes network issues.
- ``bin/network`` - a utility for gathering information about your local network.
- ``misc/org.nficano.dotfiles.DropboxSync.plist`` - runs dropbox-sync hourly via launchd.

## Installation

```bash
$ mkdir -p ~/github
$ cd github
$ git clone git@github.com:nficano/dotfiles.git
$ cd dotfiles
$ make install
