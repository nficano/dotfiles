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
$ mkdir -p ~/code
$ cd code
$ git clone git@github.com:nficano/dotfiles.git
$ cd dotfiles
$ make install
```

## Included shell scripts
```
+x                                       Make files executable.
abspath                                  Return an absolute path.
add-alias                                Create a new bash alias
adffind                                  Locates and exports Adobe Creative Cloud font
clean-up-open-with-menu                  Clean up LaunchServices
copy-path                                Copy absolute path to clipboard, with optional filename.
docker-armageddon                        Nuclear option for Docker cleanup
dots                                     Show custom shell scripts
drm                                      Remove directories recursively and forcefully.
dualtrack-merge                          Merges two audio files into a single stereo output file
exif-migrate-tags                        Copy the creation date from the EXIF data to another file.
expanduser                               Expand ~ to user home directory in paths.
extract                                  Extract any compressed archive.
find-and-copy                            Recursively find and copy all files matching a given expression.
find-and-move                            Recursively find and move all files matching a given expression.
find-dir                                 Find directories by name in directory tree.
fpwd                                     Print the path of the current Finder window.
git-copy-branch-name                     Copy the current branch name to the clipboard.
git-copy-modified-files-to-dir           Copy modified files (git status) to a specified directory.
git-forklift                             Usage: $(basename "$0") [-h] -b BRANCH_NAME -u UNTIL_HASH
git-move-last-commit-to-branch           Move the last commit to a new branch.
git-prune-merged-branches                Delete all branches that are fully merged into <merge-branch>.
git-rollback-to-commit                   Rollback git to previous commit.
git-show-ignored                         Show ignored files in git status.
git-undo-last-commit-but-keep-changes    Undo last commit but keep changes.
git-unstage-all                          Unstages all files
headers                                  Show HTTP headers of a URL.
hgrep                                    Grep for shell history.
hidedesk                                 Hide desktop icons.
is-host-up                               Check if a host is up.
is-port-open                             Check if a network port is open.
kill-by-pid                              Kill a process by id.
kill-by-port                             Kill a process running on a specified port.
line                                     Print a line from a file.
macos-clear-notifications                Clear all messages in notification center
macos-fix-audio                          Fix issue where audio stops working.
macos-fix-speech                         Fix MacOS speech synthesis.
macos-flush-dns-cache                    Flush DNS cache.
macos-restart-core-media-services        Restart core media services on macOS
macos-set-hostname                       Update hostname on MacOS.
meta                                     Show file metadata.
mkscript                                 Create a new shell script from a template
mkv-to-mp4*                              Convert all .mkv files in the current directory to .mp4.
mp4-to-mov*                              Convert all .mp4 files in the current directory to .mov.
mp4-to-webm*                             Convert all .mp4 files in the current directory to .webm.
netspeed                                 Measure connection timing metrics for a URL.
noun                                     Remove attribution from SVG files.
null                                     Ignore output of this script.
path                                     Show a pretty-print of the PATH environment variable.
permissions                              Shows the permissions of a file or directory in octal form.
pg_start                                 Start postgresql service via brew.
pg_stop                                  Stop postgresql service via brew.
pid-on-port                              Show the PID of a process running on a specified port.
pstat                                    Show a filtered, formatted, and sorted process list.
showdesk                                 Show desktop icons.
silence-removal                          Remove silence from an audio file.
slugify                                  Rename files and directories to slug fields.
strip-noun-attribution                   Strip attribution from SVG files.
svg-icon                                 Quickly make SVGs responsive and change the  fill="currentColor".
svgo*                                    Optimize all SVG files in the current directory.
t                                        Move files/directories to macOS Trash instead of permanent deletion
typo                                     Adds a typo correction to Espanso
unzip-all                                Unzip all files in the current directory.
utc                                      Show the current time as utc timestamp.
uvw                                      Wrapper for `uv` — intercepts `uv init`, proxies all else
webp*                                    Convert all .jpg, .jpeg, and .png files in the current directory to .webp.
```
