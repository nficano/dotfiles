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

## Utilities

### bin/network

#### A utility for gathering information about your local network.

```
Commands:
  -getlanhosts                discover all devices on your network.
  -getgatewayip               displays the address of your "network gateway",
                              or the edge device (ie: router) that sits
                              between you and another network (ie: the
                              Internet).
  -gethostip                  displays your host ip address
  -getmodemip                 attempts to find the ip address of your modem
                              (first hop after your router/gateway).
  -getnetworkip               the common prefix of your private ip address,
                              used to refer to your subnet as a whole.
  -getprivateip               alias to "ip host"
  -getpublicip                the globally unique address assigned to your
                              network by your isp
  -getroutingtable            display your routing table.
  -getrouterip                alias to "ip gateway"
  -getispname                 displays the name of your isp
  -probe <modem|router>       attempts to identify the operating system, open
                              ports, and running software on your modem or
                              router.
  -webconfig <modem|router>   opens the web config for your modem or router.
  -getsubnet [-o <bit|hex>]   displays your host subnet mask address ip.
```

## Installation

```bash
$ mkdir -p ~/github
$ cd github
$ git clone git@github.com:nficano/dotfiles.git
$ cd dotfiles
$ make install
