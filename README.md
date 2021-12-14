<p align="center">
  <img src="https://assets.nickficano.com/gh-dotfiles.svg" alt="dotfiles" width="360" height="112" />
  <div align="center">
    <a href="https://travis-ci.org/nficano/dotfiles"><img src="https://travis-ci.org/nficano/dotfiles.svg?branch=master" /></a>
    <img src="https://img.shields.io/github/last-commit/nficano/dotfiles.svg" />
    <img src="https://img.shields.io/github/tag/nficano/dotfiles.svg" />
    <img src="https://img.shields.io/badge/platforms-macos%20%7C%20linux-blue.svg" />
  </div>
</p>

## Nick Ficano's dotfiles

This repo contains my dotfiles, the scripts to bootstrap my Mac OS environment,
and various utilities that have no other home.

While I will outline how to install my configuration from scratch, I would
recommend using it for reference purposes only.

## Structure

- ``bin/`` - custom shell scripts
- ``home/`` - dotfiles that belong in ``$HOME``.
- ``os/`` - os-specific shell scripts, preferences, etc.

## Installation

```bash
$ mkdir -p ~/github
$ cd github
$ git clone git@github.com:nficano/dotfiles.git
$ cd dotfiles
$ make install
```
