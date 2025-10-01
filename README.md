# Dotfiles

This repository collects personal macOS/Linux dotfiles, provisioning scripts, and helper utilities. The layout keeps shell configuration, application profiles, and executable helpers in discrete directories while sharing a common Bash library for reusable behaviour.

## Repository Organization

- `bin/` – executable utilities referenced below; symlinked into `~/.bin` by `make setup-tree`.
- `home/` – version-controlled copies of dotfiles such as `gitconfig`, `tmux.conf`, and `pip.conf`; `make setup-tree` links them into `$HOME`.
- `lib/` – shared shell libraries. `lib/bash/utils` provides logging, prompting, filesystem helpers, deferred sourcing, locking, and other primitives consumed by the skeletons and shell profile. The scripts that implement the Redis-style datastore source `lib/rdb-common` for the SQLite-backed storage helper.
- `profiles/` – application-specific settings, currently an iTerm2 profile in `profiles/iterm2/profile.json`.
- `setup/` – provisioning assets. `setup/macos/mac-provision` automates a full macOS bootstrap (Xcode tools, Homebrew, defaults) and the accompanying `Brewfile` captures required packages.
- `shell/` – interactive shell entrypoints. `shell/bash/profile` exports environment variables, amends `PATH`, and lazy-loads tooling using the helpers from `lib/bash/utils`.
- `skel/` – Bash script skeletons consumed by `bin/mkscript` when scaffolding new utilities.
- `Makefile` – convenience tasks: `make install` runs the macOS provisioner, `make setup-tree` prepares directories and symlinks in the home directory, and the `deploy-*` targets bump the version tag.

## bin/ Utilities

### Shell and Workflow Helpers

- `+x` – Wraps `chmod +x` so you can mark a new script executable with `+x path/to/script`.
- `add-alias` – Appends an alias definition to `~/.bash_profile` and reminds you to reload it; run `add-alias -n gs -c "git status"` to register shortcuts without editing the file manually.
- `copy-path` – Copies the current directory or a named entry in it to the macOS clipboard; useful when sharing absolute paths.
- `dots` – Lists every file in `~/.bin` and prints the second line of each script as its description, making it easy to discover available helpers.
- `fpwd` – Uses AppleScript to print the path of the frontmost Finder window, allowing quick `cd "$(fpwd)"`.
- `hgrep` – Greps the Bash history file with regex matching while de-duplicating results, handy for retrieving past commands.
- `line` – Reads stdin and prints the specified line number (`cmd | line 5` shows the fifth match).
- `meta` – Delegates to `mdls` on macOS or `mediainfo` elsewhere to inspect file metadata.
- `mkscript` – Interactive scaffold generator: select a skeleton, provide a kebab-case name and description, and it writes an executable script in `bin/` and opens it in `$EDITOR`.
- `null` – Runs a command while discarding stdout and stderr (`null some-noisy-command`), convenient in pipelines.
- `path` – Pretty-prints the `PATH` environment variable one entry per line to confirm search order.
- `permissions` – Shows a file or directory’s permissions in symbolic and octal form (`permissions /usr/bin`).
- `t` – Moves files or directories to the macOS Trash instead of deleting them, with optional confirmation flags (`t -i big-file`).
- `typo` – Appends a typo correction to the Espanso configuration at `~/Library/Application Support/espanso/match/base.yml`.
- `uvw` – Wraps the `uv` Python tool: for `uv init` it creates or reuses a virtualenv recorded in `.envrc`, otherwise it forwards all arguments to the real binary.

### File and Directory Tools

- `abspath` – Resolves a relative path to an absolute path (`abspath ../some/file`).
- `drm` – Safety-wrapper around `rm -rf` for directories; it verifies the target exists before deletion.
- `expanduser` – Expands a path containing `~` to its real location (`expanduser ~/Downloads`).
- `extract` – Dispatches to the appropriate tool to unpack archives (zip, tar.\*, rar, 7z, etc.) in place.
- `find-and-copy` – Recursively finds files matching a glob and copies them to a destination (`find-and-copy "*.svg" ~/vectors`).
- `find-and-move` – Same as above but moves matched files (`find-and-move "*.log" archive/`).
- `find-by-extension` – Lists files with a given extension under the current tree.
- `find-by-name` – Recurses for exact filename matches (`find-by-name "*.plist"`).
- `find-dir` – Recursively finds directories by name (`find-dir build`).
- `slugify` – Renames files and directories to URL-friendly slugs, with dry-run, recursive, and exclusion options.
- `unzip-all` – Unpacks every `*.zip` in the working directory into sibling folders while leaving the archives intact.

### Media and Asset Pipelines

- `adffind` – Locates Adobe Creative Cloud fonts in CoreSync, optionally converting them to TTF or WOFF2 with FontForge/woff2 before copying them out.
- `dualtrack-merge` – Uses ffmpeg to turn two mono audio recordings into a single stereo file (first input becomes the left channel).
- `exif-migrate-tags` – Copies all EXIF metadata from one file to another via `exiftool`, useful when transcoding media.
- `mkv-to-mp4*` – Converts every `.mkv` in the current folder to `.mp4` via ffmpeg stream copy.
- `mp4-to-mov*` – Converts `.mp4` files to `.mov` in place.
- `mp4-to-webm*` – Converts `.mp4` files to `.webm`.
- `noun` – Removes attribution text elements from SVG files and reoptimises them with `svgo`, tailoring icons sourced from The Noun Project.
- `strip-noun-attribution` – Legacy helper that strips `<text>` attribution blocks from `noun*.svg` files in the current directory.
- `svg-icon` – Cleans SVG assets: optionally removes fixed dimensions, enforces `fill="currentColor"`, and processes files or directories recursively.
- `svgo*` – Runs `svgo --multipass` across all SVGs in the working directory for batch optimisation.
- `silence-removal` – Uses ffmpeg’s `silenceremove` filter to trim silence from audio files.
- `webp*` – Converts `.jpg`, `.jpeg`, and `.png` images (recursively) to `.webp` with `cwebp`.

### Git and Project Utilities

- `git-copy-branch-name` – Copies the current branch name to the clipboard for use in tickets or pull requests.
- `git-copy-modified-files-to-dir` – Template for copying `git status` modified files into a staging directory; customise the commented `cp` command to suit your workflow.
- `git-forklift` – Moves all commits after a given hash onto a new branch and rewinds the original branch to the specified tree state.
- `git-move-last-commit-to-branch` – Creates a new branch from `HEAD` and removes the last commit from the current branch.
- `git-prune-merged-branches` – Lists or deletes branches fully merged into a target branch, locally or on a remote, with optional fetch.
- `git-rebaser` – Safe rebase workflow: creates a timestamped working branch, runs `git rebase --autostash --rebase-merges -X patience`, and guides merging back.
- `git-rollback-to-commit` – Runs `git revert` for a specific commit hash.
- `git-show-ignored` – Calls `git status --ignored` to display ignored files.
- `git-theirs-rebase` – Intended helper for rebasing while preferring upstream changes; currently shells out to `git revert` and should be adjusted before use.
- `git-undo-last-commit-but-keep-changes` – Performs `git reset --soft HEAD~1` and shows status to retain working tree changes.
- `git-unstage-all` – Runs `git reset` to unstage everything.

### System, macOS, and Services

- `clean-up-open-with-menu` – Rebuilds LaunchServices registrations and restarts Finder to clear duplicate “Open With” entries.
- `macos-clear-notifications` – Kills `NotificationCenter` to empty the notification list.
- `macos-fix-audio` – Terminates `coreaudiod` when system audio stops responding.
- `macos-fix-speech` – Restarts speech synthesis daemons.
- `macos-flush-dns-cache` – Flushes DNS caches via `dscacheutil` and `mDNSResponder`.
- `macos-restart-core-media-services` – Stops key media-related processes (Dock, WindowServer, etc.) for troubleshooting display/audio issues.
- `macos-set-hostname` – Updates the system hostname, LocalHostName, and related SMB settings in one step.
- `hidedesk` / `showdesk` – Toggle Finder desktop icon visibility.
- `docker-armageddon` – Stops and removes all Docker containers, images, volumes, networks, and build cache after an explicit confirmation.
- `pg_start` / `pg_stop` – Control Homebrew’s PostgreSQL service via `brew services`.

### Network and Diagnostics

- `headers` – Fetches only the HTTP response headers for a URL using `curl -sv`.
- `ip` – Rich network report: local interfaces, default gateways, DNS servers, and public IP lookups for IPv4/IPv6.
- `is-host-up` – Reads a list of URLs from a file and prints those returning HTTP 200, useful for availability checks.
- `is-port-open` – Uses netcat to probe whether a host:port accepts TCP connections.
- `kill-by-port` – Finds the process listening on a TCP port and kills it.
- `kill-by-pid` – Simple wrapper around `sudo kill -TERM <pid>` for explicit process termination.
- `pid-on-port` – Displays processes bound to a specific port via `lsof -i`.
- `ports` – Summarises listening TCP/UDP sockets grouped by owning process.
- `pstat` – Formats `ps aux` output with colour, optional macOS process filtering, and de-duplication.
- `netspeed` – Measures DNS lookup, connect time, TLS handshake, first byte, and total request time for a given URL using `curl`.

### Local Datastore Commands

These scripts implement Redis-inspired operations backed by the helper sourced from `lib/rdb-common`, which stores data in an SQLite database.

- `kset` / `kget` – Set or retrieve a string value.
- `del` – Delete one or more keys, returning the count removed.
- `exists` – Return how many of the specified keys currently exist.
- `keys` – List keys matching a glob-style pattern.
- `incr` / `decr` – Increment or decrement an integer value atomically.
- `lpush` / `rpush` – Push values onto the head or tail of a list.
- `lpop` / `rpop` – Pop the first or last list element.
- `llen` – Report the length of a list.

### Miscellaneous Calculators

- `px-to-em` – Converts a pixel value to `em` units for a given base font size and copies the result to the clipboard.
- `utc` – Prints the current Unix epoch timestamp.

## Skeleton Files (`skel/`)

Each skeleton is a Bash template that already sources `lib/bash/utils`, enables `set -Eeuo pipefail`, provides help text with `#/` comments, and wires in the shared logging/prompt helpers.

- `skel/bash/noargs` – Minimal command pattern with `-h/--help` and optional `--verbose`, intended for scripts with no positional arguments.
- `skel/bash/args` – Adds positional argument collection while preserving the common option parser.
- `skel/bash/params-args` – Demonstrates combined flag, parameter, and positional handling (e.g. `--param value` plus extra arguments).
- `skel/bash/cron-safe` – Wraps execution with a file lock so cron jobs do not overlap.
- `skel/bash/daemon` – Long-running loop with configurable interval and graceful shutdown handling.
- `skel/bash/fileproc` – Processes files from arguments or stdin, creating a temporary work directory and supporting a dry-run mode.
- `skel/bash/interactive` – Interactive workflow with prompts, optional non-interactive mode, and default handling.
- `skel/bash/net` – HTTP client scaffold with retries, timeouts, and method/payload parameters using `curl`.
- `skel/bash/parallel` – Executes tasks concurrently with a configurable job limit and failure tracking.

## Script Creation

1. Run `bin/mkscript` from the repository root (or ensure `bin/` is on your `PATH`).
2. Choose a skeleton by number or name; press enter to accept the default first option.
3. Supply a kebab-case script name (the helper enforces this) and a short description that replaces `{{ description }}` in the template.
4. Enter the summary text when prompted. The tool writes the new script into `bin/`, marks it executable, and opens it in `$EDITOR`.
5. Replace the `TODO` comments with your logic, keeping the `#/` documentation block accurate and the `set -Eeuo pipefail` directive intact.
6. When the script reuses shared facilities, keep sourcing `../lib/bash/utils` so you can call helpers such as `log.info`, `prompt.ask_yes_no`, `fs.mktmp`, `lock.acquire`, and `shell.defer`.
7. Use `bin/dots` to confirm the description renders nicely and consider running `bin/+x` if you edit a script outside of `mkscript`.

Conventions to follow when authoring new scripts:

- Keep filenames in kebab-case and store executables under `bin/` so `shell/bash/profile` adds them to the `PATH`.
- Document usage with `#/` comment lines at the top so `script.usage` can emit help text automatically.
- Prefer the common option parsing helpers (`script.parse_common` or the patterns shown in the skeletons) to deliver consistent `-h/--help` and `-v/--verbose` behaviour.
- Use the logging (`log.info`, `log.warn`, `log.error`), prompting, locking, and filesystem helpers from `lib/bash/utils` instead of reimplementing them.
- When creating new media or conversion scripts, follow the examples that operate on the current working directory and respect standard tools such as ffmpeg or svgo.
