# Dotfiles

This repository collects personal macOS/Linux dotfiles, provisioning scripts, and helper utilities. The layout keeps shell configuration, application profiles, and executable helpers in discrete directories while sharing a common Bash library for reusable behaviour.

## Repository Organization

- **`bin/`** – Executable utilities referenced below; symlinked into `~/.bin` by `make setup-tree`
- **`home/`** – Version-controlled copies of dotfiles such as `gitconfig`, `tmux.conf`, and `pip.conf`; `make setup-tree` links them into `$HOME`
- **`lib/`** – Shared shell libraries. `lib/bash/utils` provides logging, prompting, filesystem helpers, deferred sourcing, locking, and other primitives consumed by the skeletons and shell profile. The scripts that implement the key/value datastore source `lib/envdb` for storing environment-like data.
- **`profiles/`** – Application-specific settings, currently an iTerm2 profile in `profiles/iterm2/profile.json`
- **`setup/`** – Provisioning assets. `setup/macos/mac-provision` now supports dry-runs, change detection, config syncing, and Homebrew automation. `setup/macos/Brewfile` captures brew dependencies and `setup/macos/defaults.conf` records macOS `defaults` managed by the provisioner
- **`shell/`** – Interactive shell entrypoints. `shell/bash/profile` exports environment variables, amends `PATH`, and lazy-loads tooling using the helpers from `lib/bash/utils`
- **`skel/`** – Bash script skeletons consumed by `bin/script-scaffold` when scaffolding new utilities
- **`Makefile`** – Convenience tasks: `make install` runs the macOS provisioner, `make setup-tree` prepares directories and symlinks in the home directory, and the `deploy-*` targets bump the version tag

## macOS Provisioning

`setup/macos/mac-provision` bootstraps and reconciles a macOS workstation. Highlights:

- Performs a dry-run (`setup/macos/mac-provision --dry-run`) that shows each step, the detected drift (missing brew formulae, differing defaults, hidden directories, firewall state), and the commands that would run.
- Applies configuration with loaders/spinners while writing defaults, refreshing file associations, and regenerating Brewfiles so long-running steps stay responsive.
- Reads desired user defaults from `setup/macos/defaults.conf` (`domain|key|type|value`). Use `setup/macos/mac-provision --update-defaults` to rewrite the file from current system settings (dropping keys that no longer resolve) or edit it manually to add more defaults.
- Keeps Homebrew aligned with `setup/macos/Brewfile`; run `setup/macos/mac-provision --update-brewfile` to dump the current system state back into the repo, or `--update-only` to perform configuration dumps without provisioning.
- Ensures the following during a full run: Xcode CLI tools and license acceptance, Homebrew installation, Brew bundle reconciliation, duti-based file associations, curated macOS defaults (keyboard repeat, Finder/Dock tweaks, Bluetooth audio quality, screenshot location, etc.), vendor directory visibility, `pipx` installation, and enabling the application firewall.

Combine the flags to suit your workflow. Examples:

```bash
# Inspect the changes without modifying the system
setup/macos/mac-provision --dry-run

# Sync Brewfile and defaults, but stop before provisioning
setup/macos/mac-provision --update-brewfile --update-defaults --update-only

# Apply everything non-interactively
setup/macos/mac-provision --yes --non-interactive
```

## bin/ Utilities

### Shell and Workflow Helpers

- **`bin-list-scripts`** – Lists every file in `~/.bin` and prints the second line of each script as its description, making it easy to discover available helpers
- **`command-null-run`** – Runs a command while discarding stdout and stderr (`command-null-run some-noisy-command`), convenient in pipelines
- **`espanso-add-typo`** – Appends a typo correction to the Espanso configuration at `~/Library/Application Support/espanso/match/base.yml`
- **`file-mark-executable`** – Wraps `chmod +x` so you can make a new script executable with `file-mark-executable path/to/script`
- **`file-metadata`** – Delegates to `mdls` on macOS or `mediainfo` elsewhere to inspect file metadata
- **`file-permissions`** – Shows a file or directory's permissions in symbolic and octal form (`file-permissions /usr/bin`)
- **`finder-front-path`** – Uses AppleScript to print the path of the frontmost Finder window, allowing quick `cd "$(finder-front-path)"`
- **`history-grep`** – Greps the Bash history file with regex matching while de-duplicating results, handy for retrieving past commands
- **`path-copy-clipboard`** – Copies the current directory or a named entry in it to the macOS clipboard; useful when sharing absolute paths
- **`path-print`** – Pretty-prints the `PATH` environment variable one entry per line to confirm search order
- **`script-scaffold`** – Interactive scaffold generator: select a skeleton, provide a kebab-case name and description, and it writes an executable script in `bin/` and opens it in `$EDITOR`
- **`shell-add-alias`** – Appends an alias definition to `~/.bash_profile` and reminds you to reload it; run `shell-add-alias -n gs -c "git status"` to register shortcuts without editing the file manually
- **`text-line`** – Reads stdin and prints the specified line number (`cmd | text-line 5` shows the fifth match)
- **`trash`** – Moves files or directories to the macOS Trash instead of deleting them, with optional confirmation flags (`t -i big-file`)
- **`uv-init-helper`** – Wraps the `uv` Python tool: for `uv init` it creates or reuses a virtualenv recorded in `.envrc`, otherwise it forwards all arguments to the real binary

### File and Directory Tools

- **`path-resolve`** – Resolves a relative path to an absolute path (`path-resolve ../some/file`)
- **`dir-remove-safe`** – Safety wrapper around `rm -rf` for directories; it verifies the target exists before deletion
- **`path-expand-tilde`** – Expands a path containing `~` to its real location (`path-expand-tilde ~/Downloads`)
- **`archive-extract`** – Dispatches to the appropriate tool to unpack archives (zip, tar.\*, rar, 7z, etc.) in place
- **`find-copy-matches`** – Recursively finds files matching a glob and copies them to a destination (`find-copy-matches "*.svg" ~/vectors`)
- **`find-move-matches`** – Same as above but moves matched files (`find-move-matches "*.log" archive/`)
- **`find-extension`** – Lists files with a given extension under the current tree[^1]
- **`find-filename`** – Recurses for exact filename matches (`find-filename "*.plist"`)[^1]
- **`find-directory`** – Recursively finds directories by name (`find-directory build`)
- **`path-slugify`** – Renames files and directories to URL-friendly slugs, with dry-run, recursive, and exclusion options
- **`zip-unpack-all`** – Unpacks every `*.zip` in the working directory into sibling folders while leaving the archives intact

[^1]: I gave up trying to remember `find` syntax.

### Media and Asset Pipelines

- **`adobe-font-export`** – Extracts Adobe Creative Cloud fonts from CoreSync, optionally converting them to TTF or WOFF2 via FontForge/woff2 before copying them out
- **`audio-stereo-merge`** – Uses ffmpeg to turn two mono audio recordings into a single stereo track (first input becomes the left channel)
- **`audio-trim-silence`** – Uses ffmpeg's `silenceremove` filter to trim silence from audio files
- **`convert-to-mp4`** – Converts a single media file (mkv/mov/avi/webm/gif, etc.) to `.mp4`
- **`convert-to-webp`** – Converts common image/video formats to `.webp` via ffmpeg
- **`exif-copy-tags`** – Copies all EXIF metadata from one file to another via `exiftool`, useful when transcoding media
- **`svg-icon-normalize`** – Cleans SVG assets: optionally removes fixed dimensions, enforces `fill="currentColor"`, and processes files or directories recursively
- **`svg-noun-clean`** – "Denoundify" text elements from SVG files and reoptimise them with `svgo`.[^2]
- **`svg-noun-legacy`** – Legacy helper that strips `<text>` attribution blocks from `noun*.svg` files in the current directory
- **`svg-optimize-all`** – Runs `svgo --multipass` across all SVGs in the working directory for batch optimisation

[^2]: Don't judge me.

### Git and Project Utilities

- **`git-branch-to-clipboard`** – Copies the current branch name to the clipboard for use in tickets or pull requests
- **`git-export-modified-files`** – Template for copying `git status` modified files into a staging directory; customise the commented `cp` command to suit your workflow
- **`git-list-ignored`** – Calls `git status --ignored` to display ignored files
- **`git-peel-last-commit`** – Creates a new branch from `HEAD` and removes the last commit from the current branch
- **`git-prune-merged`** – Lists or deletes branches fully merged into a target branch, locally or on a remote, with optional fetch
- **`git-rebase-prefer-upstream`** – Intended helper for rebasing while preferring upstream changes; currently shells out to `git revert` and should be adjusted before use
- **`git-rebase-verify`** - Interactively validate a rebased branch against a base branch.
- **`git-release-tag-name`** - Generates deterministic tag release names based off of commit hash.
- **`git-reset-stage`** – Runs `git reset` to unstage everything
- **`git-revert-to`** – Runs `git revert` for a specific commit hash
- **`git-safe-rebase`** – Safe rebase workflow: creates a timestamped working branch, runs `git rebase --autostash --rebase-merges -X patience`, and guides merging back
- **`git-soft-reset-last`** – Performs `git reset --soft HEAD~1` and shows status to retain working tree changes
- **`git-split-after`** – Moves all commits after a given hash onto a new branch and rewinds the original branch to the specified tree state

### System, macOS, and Services

- **`clean-up-open-with-menu`** – Rebuilds LaunchServices registrations and restarts Finder to clear duplicate "Open With" entries
- **`docker-wipe-all`** – Stops and removes all Docker containers, images, volumes, networks, and build cache after an explicit confirmation
- **`finder-hide-desktop` / `finder-show-desktop`** – Toggle Finder desktop icon visibility
- **`macos-audio-reset`** – Terminates `coreaudiod` when system audio stops responding
- **`macos-coremedia-restart`** – Stops key media-related processes (Dock, WindowServer, etc.) for troubleshooting display/audio issues
- **`macos-dns-flush`** – Flushes DNS caches via `dscacheutil` and `mDNSResponder`
- **`macos-hostname-set`** – Updates the system hostname, LocalHostName, and related SMB settings in one step
- **`macos-notifications-clear`** – Kills `NotificationCenter` to empty the notification list
- **`postgres-start` / `postgres-stop`** – Control Homebrew's PostgreSQL service via `brew services`

### Network and Diagnostics

- **`http-show-headers`** – Fetches only the HTTP response headers for a URL using `curl -sv`
- **`network-check-host`** – Reads a list of URLs from a file and prints those returning HTTP 200, useful for availability checks
- **`network-check-port`** – Uses netcat to probe whether a host:port accepts TCP connections
- **`network-info`** – Rich network report: local interfaces, default gateways, DNS servers, and public IP lookups for IPv4/IPv6
- **`network-listeners`** – Summarises listening TCP/UDP sockets grouped by owning process
- **`network-measure-ttfb`** – Measures DNS lookup, connect time, TLS handshake, first byte, and total request time for a given URL using `curl`
- **`network-pid-on-port`** – Displays processes bound to a specific port via `lsof -i`
- **`process-kill-pid`** – Simple wrapper around `sudo kill -TERM <pid>` for explicit process termination
- **`process-kill-port`** – Finds the process listening on a TCP port and kills it
- **`process-list`** – Formats `ps aux` output with colour, optional macOS process filtering, and de-duplication

### Local Datastore Commands

These scripts implement Redis-inspired operations backed by the helper sourced from `lib/rdb-common`, which stores data in an SQLite database.

- **`kv-set` / `kv-get`** – Set or retrieve a string value
- **`kv-delete`** – Delete one or more keys, returning the count removed
- **`kv-exists`** – Return how many of the specified keys currently exist
- **`kv-increment` / `kv-decrement`** – Increment or decrement an integer value atomically
- **`kv-list-keys`** – List keys matching a glob-style pattern
- **`kv-list-length`** – Report the length of a list
- **`kv-list-pop-left` / `kv-list-pop-right`** – Pop the first or last list element
- **`kv-list-push-left` / `kv-list-push-right`** – Push values onto the head or tail of a list

### Miscellaneous Calculators

- **`css-px-to-em`** – Converts a pixel value to `em` units for a given base font size and copies the result to the clipboard
- **`time-epoch`** – Prints the current Unix epoch timestamp

## Skeleton Files (`skel/`)

Each skeleton is a Bash template that already sources `lib/bash/utils`, enables `set -Eeuo pipefail`, provides help text with `#/` comments, and wires in the shared logging/prompt helpers.

- **`skel/bash/noargs`** – Minimal command pattern with `-h/--help` and optional `--verbose`, intended for scripts with no positional arguments
- **`skel/bash/args`** – Adds positional argument collection while preserving the common option parser
- **`skel/bash/params-args`** – Demonstrates combined flag, parameter, and positional handling (e.g. `--param value` plus extra arguments)
- **`skel/bash/cron-safe`** – Wraps execution with a file lock so cron jobs do not overlap
- **`skel/bash/daemon`** – Long-running loop with configurable interval and graceful shutdown handling
- **`skel/bash/fileproc`** – Processes files from arguments or stdin, creating a temporary work directory and supporting a dry-run mode
- **`skel/bash/interactive`** – Interactive workflow with prompts, optional non-interactive mode, and default handling
- **`skel/bash/net`** – HTTP client scaffold with retries, timeouts, and method/payload parameters using `curl`
- **`skel/bash/parallel`** – Executes tasks concurrently with a configurable job limit and failure tracking

## Script Creation

1. Run `bin/script-scaffold` from the repository root (or ensure `bin/` is on your `PATH`)
2. Choose a skeleton by number or name; press enter to accept the default first option
3. Supply a kebab-case script name (the helper enforces this) and a short description that replaces `{{ description }}` in the template
4. Enter the summary text when prompted. The tool writes the new script into `bin/`, marks it executable, and opens it in `$EDITOR`
5. Replace the `TODO` comments with your logic, keeping the `#/` documentation block accurate and the `set -Eeuo pipefail` directive intact
6. When the script reuses shared facilities, keep sourcing `../lib/bash/utils` so you can call helpers such as `log.info`, `prompt.ask_yes_no`, `fs.mktmp`, `lock.acquire`, and `shell.defer`
7. Use `bin/bin-list-scripts` to confirm the description renders nicely and consider running `bin/file-mark-executable` if you edit a script outside of `script-scaffold`

### Conventions to follow when authoring new scripts:

- Keep filenames in kebab-case and store executables under `bin/` so `shell/bash/profile` adds them to the `PATH`
- Document usage with `#/` comment lines at the top so `script.usage` can emit help text automatically
- Prefer the common option parsing helpers (`script.parse_common` or the patterns shown in the skeletons) to deliver consistent `-h/--help` and `-v/--verbose` behaviour
- Use the logging (`log.info`, `log.warn`, `log.error`), prompting, locking, and filesystem helpers from `lib/bash/utils` instead of reimplementing them
- When creating new media or conversion scripts, follow the examples that operate on the current working directory and respect standard tools such as ffmpeg or svgo

## TODO:

- upload file to s3 public bucket and return the url to clipboard
- backup to s3 and backup to dropbox w/ incremental changes
- add-alias should support a flag to add to private bash_profile
- script to show the installed OS and version
