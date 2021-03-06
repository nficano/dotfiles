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

- ``bin/`` - all of my custom executable scripts.
- ``misc/`` - stuff that doesn't have a home.
- ``home/`` - config files that I symlink to my home directory.

## Reference

- ``bin/+x`` - shorthand for ``chmod +x``.
- ``bin/dotfiles`` - a utility for managing dotfiles.
- ``bin/git-copy-branch-name`` - does what you'd expect.
- ``bin/git-move-last-commit-to-branch`` - does what you'd expect.
- ``bin/git-unstage-all`` - does what you'd expect.
- ``bin/kill-by-port`` - kills a process given a port its listening on
- ``bin/pid-by-port`` - kill-by-port's non-destructive brother
- ``bin/network`` - a utility for gathering information about your local network.
- ``misc/bootstrap`` - setup/update my mac os environment.
- ``misc/install`` - install dotfiles remotely.
- ``misc/lan-doctor`` - detects and repairs network issues (runs on router via cron).
- ``misc/org.nficano.dotfiles.DropboxSync.plist`` - runs sync-to-dropbox hourly via launchd.
- ``misc/renew-ssl-cert`` - automatic ssl cert renewal (runs on router via cron).
- ``misc/route53-ddns`` - script to parodically make sure a subdomain points to by public ip address.
- ``misc/sync-to-dropbox`` - syncronizes frequently updated files to dropbox.

## Utilities

### network

A utility for gathering information about your local network.

##### Commands

```
-getlanhosts                discover all devices on your network.
-getgatewayip               displays the address of your "network gateway", or the edge device (ie: router) that sits between you and another network (ie: the Internet).
-gethostip                  displays your host ip address attempts to find the ip address of your modem (first hop after your router/gateway).
-getnetworkip               the common prefix of your private ip address, used to refer to your subnet as a whole.
-getprivateip               alias to "ip host"
-getpublicip                the globally unique address assigned to your network by your isp
-getroutingtable            display your routing table.
-getarptable                display your address resolution protocol (arp) table.
-getrouterip                alias to "ip gateway"
-getispname                 displays the name of your isp
-probe <modem|router>       attempts to identify the operating system, open ports, and running software on your modem or router.
-exploitscan [target]       runs an advanced vulnerability scan against your current subnet (or target ip if provided).
-osscan [target]            runs an *aggressive* operating system/version detection scan against your current subnet (or target ip if provided).
-snmpscan [target]          runs a simple network management protocol (snmp) scan against your current subnet (or target ip if provided).
-webconfig <modem|router>   opens the web config for your modem or router.
-getsubnet [-o <bit|hex>]   displays your host subnet mask address ip.
```

### dotfiles

A utility for managing dotfiles.

##### Commands

```
-edit               opens ``~/.bash_profile`` in your editor.
-upgrade            upgrade to the latest dotfiles release.
-backup             creates local dotfiles backup.
```

## Installation

#### Method 1 (the ``git clone`` method)

```bash
$ mkdir -p ~/github
$ cd github
$ git clone git@github.com:nficano/dotfiles.git
$ cd dotfiles
$ make install
```

#### Method 2 (the ``curl`` method)

```bash
$ curl sh.nickficano.com | sh
```

#### Method 3 (the ``wget`` method)

```bash
$ wget -qO- sh.nickficano.com | sh
```
