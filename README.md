# Dotfiles

This repository collects personal macOS/Linux dotfiles, provisioning scripts, and helper utilities. The layout keeps shell configuration, application profiles, and executable helpers in discrete directories while sharing a common Bash library for reusable behaviour.

## Repository Organization

- **`bin/`** - Executable utilities referenced below; symlinked into `~/.bin` by `make setup-tree`
- **`home/`** - Version-controlled copies of dotfiles such as `gitconfig`, `tmux.conf`, and `pip.conf`; `make setup-tree` links them into `$HOME`
- **`lib/`** - Shared shell libraries. `lib/bash/initrc` bootstraps a Python-inspired stdlib composed of modules like `logging`, `strings`, `os`, `runtime`, and `ui/core`. Scripts import that aggregator for logging, prompting, filesystem helpers, deferred sourcing, locking, and other primitives, while specialised tools still pull in peers such as `lib/envdb` for the key/value datastore.
- **`profiles/`** - Application-specific settings, currently an iTerm2 profile in `profiles/iterm2/profile.json`
- **`setup/`** - Provisioning assets. `setup/macos/mac-provision` now supports dry-runs, change detection, config syncing, and Homebrew automation. `setup/macos/Brewfile` captures brew dependencies and `setup/macos/defaults.conf` records macOS `defaults` managed by the provisioner
- **`shell/`** - Interactive shell entrypoints. `shell/bash/profile` exports environment variables, amends `PATH`, and lazy-loads tooling using the helpers from `lib/bash/initrc`
- **`skel/`** - Bash script skeletons consumed by `bin/script-scaffold` when scaffolding new utilities
- **`Makefile`** - Convenience tasks: `make install` runs the macOS provisioner, `make setup-tree` prepares directories and symlinks in the home directory, and the `deploy-*` targets bump the version tag

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

- **`bin-list-scripts`** - Lists every file in `~/.bin` and prints the second line of each script as its description, making it easy to discover available helpers
- **`command-null-run`** - Runs a command while discarding stdout and stderr (`command-null-run some-noisy-command`), convenient in pipelines
- **`espanso-add-typo`** - Appends a typo correction to the Espanso configuration at `~/Library/Application Support/espanso/match/base.yml`
- **`file-mark-executable`** - Wraps `chmod +x` so you can make a new script executable with `file-mark-executable path/to/script`
- **`file-metadata`** - Delegates to `mdls` on macOS or `mediainfo` elsewhere to inspect file metadata
- **`file-permissions`** - Shows a file or directory's permissions in symbolic and octal form (`file-permissions /usr/bin`)
- **`finder-front-path`** - Uses AppleScript to print the path of the frontmost Finder window, allowing quick `cd "$(finder-front-path)"`
- **`history-grep`** - Greps the Bash history file with regex matching while de-duplicating results, handy for retrieving past commands
- **`path-copy-clipboard`** - Copies the current directory or a named entry in it to the macOS clipboard; useful when sharing absolute paths
- **`path-print`** - Pretty-prints the `PATH` environment variable one entry per line to confirm search order
- **`script-scaffold`** - Interactive scaffold generator: select a skeleton, provide a kebab-case name and description, and it writes an executable script in `bin/` and opens it in `$EDITOR`
- **`shell-add-alias`** - Appends an alias definition to `~/.bash_profile` and reminds you to reload it; run `shell-add-alias -n gs -c "git status"` to register shortcuts without editing the file manually
- **`text-line`** - Reads stdin and prints the specified line number (`cmd | text-line 5` shows the fifth match)
- **`trash`** - Moves files or directories to the macOS Trash instead of deleting them, with optional confirmation flags (`t -i big-file`)
- **`uv-init-helper`** - Wraps the `uv` Python tool: for `uv init` it creates or reuses a virtualenv recorded in `.envrc`, otherwise it forwards all arguments to the real binary

### File and Directory Tools
- **`copyx`** - Simple backup automation to S3.
- **`s3-upload-and-link`** - Upload files to S3 and copy the shareable URL to the clipboard (similar to CloudApp)
- **`path-resolve`** - Resolves a relative path to an absolute path (`path-resolve ../some/file`)
- **`dir-remove-safe`** - Safety wrapper around `rm -rf` for directories; it verifies the target exists before deletion
- **`path-expand-tilde`** - Expands a path containing `~` to its real location (`path-expand-tilde ~/Downloads`)
- **`archive-extract`** - Dispatches to the appropriate tool to unpack archives (zip, tar.\*, rar, 7z, etc.) in place
- **`find-copy-matches`** - Recursively finds files matching a glob and copies them to a destination (`find-copy-matches "*.svg" ~/vectors`)
- **`find-move-matches`** - Same as above but moves matched files (`find-move-matches "*.log" archive/`)
- **`find-extension`** - Lists files with a given extension under the current tree[^1]
- **`find-filename`** - Recurses for exact filename matches (`find-filename "*.plist"`)[^1]
- **`find-directory`** - Recursively finds directories by name (`find-directory build`)
- **`path-slugify`** - Renames files and directories to URL-friendly slugs, with dry-run, recursive, and exclusion options
- **`zip-unpack-all`** - Unpacks every `*.zip` in the working directory into sibling folders while leaving the archives intact

[^1]: I gave up trying to remember `find` syntax.

### Media and Asset Pipelines

- **`adobe-font-export`** - Extracts Adobe Creative Cloud fonts from CoreSync, optionally converting them to TTF or WOFF2 via FontForge/woff2 before copying them out
- **`audio-stereo-merge`** - Uses ffmpeg to turn two mono audio recordings into a single stereo track (first input becomes the left channel)
- **`audio-trim-silence`** - Uses ffmpeg's `silenceremove` filter to trim silence from audio files
- **`convert-to-mp4`** - Converts a single media file (mkv/mov/avi/webm/gif, etc.) to `.mp4`
- **`convert-to-webp`** - Converts common image/video formats to `.webp` via ffmpeg
- **`exif-copy-tags`** - Copies all EXIF metadata from one file to another via `exiftool`, useful when transcoding media
- **`svg-icon-normalize`** - Cleans SVG assets: optionally removes fixed dimensions, enforces `fill="currentColor"`, and processes files or directories recursively
- **`svg-optimize-all`** - Runs `svgo --multipass` across all SVGs in the working directory for batch optimisation

### Git and Project Utilities

- **`git-branch-to-clipboard`** - Copies the current branch name to the clipboard for use in tickets or pull requests
- **`git-export-modified-files`** - Template for copying `git status` modified files into a staging directory; customise the commented `cp` command to suit your workflow
- **`git-list-ignored`** - Calls `git status --ignored` to display ignored files
- **`git-peel-last-commit`** - Creates a new branch from `HEAD` and removes the last commit from the current branch
- **`git-prune-merged`** - Lists or deletes branches fully merged into a target branch, locally or on a remote, with optional fetch
- **`git-rebase-prefer-upstream`** - Intended helper for rebasing while preferring upstream changes; currently shells out to `git revert` and should be adjusted before use
- **`git-rebase-verify`** - Interactively validate a rebased branch against a base branch.
- **`git-release-tag-name`** - Generates deterministic tag release names based off of commit hash.
- **`git-reset-stage`** - Runs `git reset` to unstage everything
- **`git-revert-to`** - Runs `git revert` for a specific commit hash
- **`git-safe-rebase`** - Safe rebase workflow: creates a timestamped working branch, runs `git rebase --autostash --rebase-merges -X patience`, and guides merging back
- **`git-soft-reset-last`** - Performs `git reset --soft HEAD~1` and shows status to retain working tree changes
- **`git-split-after`** - Moves all commits after a given hash onto a new branch and rewinds the original branch to the specified tree state

### System, macOS, and Services

- **`clean-up-open-with-menu`** - Rebuilds LaunchServices registrations and restarts Finder to clear duplicate "Open With" entries
- **`docker-wipe-all`** - Stops and removes all Docker containers, images, volumes, networks, and build cache after an explicit confirmation
- **`finder-hide-desktop` / `finder-show-desktop`** - Toggle Finder desktop icon visibility
- **`macos-audio-reset`** - Terminates `coreaudiod` when system audio stops responding
- **`macos-coremedia-restart`** - Stops key media-related processes (Dock, WindowServer, etc.) for troubleshooting display/audio issues
- **`macos-dns-flush`** - Flushes DNS caches via `dscacheutil` and `mDNSResponder`
- **`macos-hostname-set`** - Updates the system hostname, LocalHostName, and related SMB settings in one step
- **`macos-notifications-clear`** - Kills `NotificationCenter` to empty the notification list
- **`pkg-manager`** - Manage packages via the first supported package manager detected on the system. (wip)
- **`postgres-start` / `postgres-stop`** - Control Homebrew's PostgreSQL service via `brew services`

### Network and Diagnostics

- **`http-show-headers`** - Fetches only the HTTP response headers for a URL using `curl -sv`
- **`network-check-host`** - Reads a list of URLs from a file and prints those returning HTTP 200, useful for availability checks
- **`network-check-port`** - Uses netcat to probe whether a host:port accepts TCP connections
- **`network-info`** - Rich network report: local interfaces, default gateways, DNS servers, and public IP lookups for IPv4/IPv6
- **`network-listeners`** - Summarises listening TCP/UDP sockets grouped by owning process
- **`network-measure-ttfb`** - Measures DNS lookup, connect time, TLS handshake, first byte, and total request time for a given URL using `curl`
- **`network-pid-on-port`** - Displays processes bound to a specific port via `lsof -i`
- **`process-kill-pid`** - Simple wrapper around `sudo kill -TERM <pid>` for explicit process termination
- **`process-kill-port`** - Finds the process listening on a TCP port and kills it
- **`process-list`** - Formats `ps aux` output with colour, optional macOS process filtering, and de-duplication

### Local Datastore Commands

These scripts implement Redis-inspired operations backed by the helper sourced from `lib/rdb-common`, which stores data in an SQLite database.

- **`kv-set` / `kv-get`** - Set or retrieve a string value
- **`kv-delete`** - Delete one or more keys, returning the count removed
- **`kv-exists`** - Return how many of the specified keys currently exist
- **`kv-increment` / `kv-decrement`** - Increment or decrement an integer value atomically
- **`kv-list-keys`** - List keys matching a glob-style pattern
- **`kv-list-length`** - Report the length of a list
- **`kv-list-pop-left` / `kv-list-pop-right`** - Pop the first or last list element
- **`kv-list-push-left` / `kv-list-push-right`** - Push values onto the head or tail of a list

### Miscellaneous

- **`css-px-to-em`** - Converts a pixel value to `em` units for a given base font size and copies the result to the clipboard
- **`time-epoch`** - Prints the current Unix epoch timestamp
- **`nanoid`** - Generate short, URL safe unique IDs.

## CopyX

`copyx` runs incremental backups on an interval using a YAML configuration. `make setup-tree` symlinks `home/.config/copyx/config.yml` into `~/.config/copyx/config.yml`, and `shell/bash/profile` exports `COPYX_CONFIG` so the script picks it up without extra flags.

- **Configuration** - The config supports `backup_root` (local path or `s3://` URI), optional `machine_id`, `sources`, `exclude` patterns, and `max_size_bytes` to skip files above a byte threshold. When `backup_root` targets the filesystem, `copyx` shells out to `rsync`; S3 destinations use `aws s3 sync/cp` with the same include/exclude semantics.
- **Machine scoping** - If `machine_id` is omitted, the helper reads `~/.machine_id` (populated by `setup/macos/mac-provision`) and falls back to the current hostname. Each run writes into a `<machine_id>/` subdirectory so multiple hosts can share the same backup bucket.
- **Scheduling** - `copyx --interval <seconds>` keeps a loop running (default 3600s). `copyx --launchd-load` generates `~/Library/LaunchAgents/com.nficano.copyx.plist`, bootstraps it with `launchctl`, and tails logs under `~/Library/Logs/copyx`. Use `--launchd-unload` to tear it down.
- **Spot runs** - `copyx --oneshot` executes a single pass; add `--dry-run` or `--verbose` to inspect the planned rsync/S3 operations before committing.
- **Inspection tools** - `copyx --preview /path/to/dir` prints the files from that subtree that would be included or skipped after applying exclude rules. `--show-files` emits the same include/skip summary for every configured source before syncing (override the default 200-line cap with `--show-files=all` or `COPYX_SHOW_FILES_LIMIT`).
- **Progress & cleanup** - `--progress` enables per-file progress output for both rsync and S3. `--purge-backup --yes` wipes the current machine’s destination directory or bucket prefix, with `--dry-run` available for a safety check.


### Environment Variables

| Name | Required | Description | Default |
|------|-----------|-------------|----------|
| `COPYX_CONFIG` | ✓ | Path to YAML config file.| — |

#### Configuration options
| Name | Required | Description | Default |
|------|-----------|-------------|----------|
| `backup_root` | ✓ | Destination directory (path or `s3://` URI) for synced data. | — |
| `machine_id` | ✗ | Host directory in `backup_root` (supports a `.machine_id` file in `$HOME` directory.) | `$(hostname)` |
| `sources` | ✓ | List of paths/globs to backup. | — |
| `exclude` | ✓ | List of paths/globs to exclude. | — |
| `max_size_bytes` | ✗ | Excludes large files.  | `-inf` |



### Sample config file:
```yaml
# Example configuration for the copyx utility.
#
# Configure the root destination for snapshots, the identifier for this
# machine (used to create a sub-folder), and the list of paths or glob
# expressions that should be replicated.
#
# Use the optional `exclude` section to skip matching paths during syncs.
# Set `max_size_bytes` to skip files larger than the specified number of bytes.


#/    backup_root   Destination directory (path or s3:// URI) for synced data
#/    machine_id    Optional machine identifier (hostname used if omitted)
#/    sources       List of paths/globs to replicate
#/    exclude       Optional list of rsync/s3 exclude patterns
#/    max_size_bytes  Optional per-file size limit; larger files are skipped

backup_root: s3://s3.us-east-1.amazonaws.com/mybucket
# machine_id:
max_size_bytes: 52428800  # 50 MiB
sources:
  - $HOME/Desktop
  - /etc/hosts
  - $HOME/.bash_history
  - $HOME/.gitconfig.local
  - $HOME/.profile.local
  - $HOME/.ssh
exclude:
  - '**/.cache'
  - '**/.DS_Store'
  - '**/.dump'
  - '**/.git'
  - '**/tmp'
```


## Spell Correct

`spell-correct' is spell check and correction utility that uses ChatGPT for spelling correction.

**Usage**
```bash
spell-correct leasure
# Copied correction "leisure" to the clipboard
```

#### Environment Variables

| Name | Required | Description | Default |
|------|-----------|-------------|----------|
| `OPENAI_API_KEY` | ✓ | Your OpenAI API key used for authentication. | — |
| `SPELL_CORRECT_OPENAI_MODEL` | ✗ | Model used for correction. | `gpt-4o-mini` |
| `SPELL_CORRECT_OPENAI_AGENT` | ✗ | Agent name defined in `.agents` file. | `spell-check` |
| `SPELL_CORRECT_OPENAI_TEMPERATURE` | ✗ | Controls randomness of model output. | `0` |

---

### Autoflags

`autoflags` converts natural language intents into safe shell commands. *(Work in progress.)*

**Usage**
```bash
autoflags git "rename current branch to feature/xyz"
# git branch -m feature/xyz
# Proceed with execution? [y/N]

autoflags find "all files with the extension png"
# find . -type f -name "*.png"
# Proceed with execution? [y/N]

autoflags ffmpeg "convent input.mov to output.webm"
# ffmpeg -i input.mov -c:v libvpx-vp9 -b:v 2M -c:a libopus output.webm
# Proceed with execution? [y/N]
```

#### Environment Variables

| Name | Required | Description | Default |
|------|-----------|-------------|----------|
| `OPENAI_API_KEY` | ✓ | Your OpenAI API key used for authentication. | — |
| `AUTOFLAGS_YES` | ✗ | Run without confirmation prompt. | `false` |
| `AUTOFLAGS_PRINT` | ✗ | Show suggested command without executing. | `false` |
| `AUTOFLAGS_COPY` | ✗ | Copy command to clipboard (implies `AUTOFLAGS_PRINT=true`). | `false` |
| `AUTOFLAGS_ALLOW_ALT` | ✗ | Allow AI to suggest alternate tools or commands. | — |
| `AUTOFLAGS_CONFIRM_DEFAULT` | ✗ | Default answer when prompted (Y or N). | `N` |
| `AUTOFLAGS_REQUIRE_WHICH` | ✗ | Verify that suggested alternative command exists. | `false` |
| `AUTOFLAGS_NO_CLIPBOARD` | ✗ | Disable automatic clipboard copy. | `false` |
| `AUTOFLAGS_CONTEXT` | ✗ | Add extra context to AI prompt. | — |
| `AUTOFLAGS_OPENAI_MODEL` | ✗ | Model used for generation. | `gpt-4o-mini` |
| `AUTOFLAGS_OPENAI_AGENT` | ✗ | Agent name defined in `.agents` file. | `autoflags` |
| `AUTOFLAGS_OPENAI_TEMPERATURE` | ✗ | Controls randomness of model output. | `0` |

---

### s3-upload-and-link

Uploads a file to S3 and copies the shareable URL to your clipboard.

**Usage**
```bash
s3-upload-and-link ubuntu-24.04.3-desktop-amd64.iso
# https://s3.us-east-1.amazonaws.com/mybucket/9oe3HVzO.iso
```

#### Environment Variables

| Name | Required | Description | Default |
|------|-----------|-------------|----------|
| `S3_UPLOAD_LINK_BUCKET` | ✓ | S3 bucket name (supports optional `s3://` prefix). | — |
| `S3_UPLOAD_LINK_PREFIX` | ✗ | Optional key prefix for uploaded objects. | — |
| `S3_UPLOAD_LINK_URL_BASE` | ✗ | Base HTTPS URL used to construct share links. | — |
| `S3_UPLOAD_LINK_BUCKET_REGION` | ✗ | Region used for default URL generation. | — |
| `S3_UPLOAD_LINK_ACL` | ✗ | ACL for `aws s3 cp`. | `public-read` |
| `S3_UPLOAD_LINK_CACHE_CONTROL` | ✗ | `Cache-Control` header for uploaded object. | — |
| `S3_UPLOAD_LINK_CONTENT_TYPE` | ✗ | Explicit `Content-Type` override. | — |
| `S3_UPLOAD_LINK_ID_LENGTH` | ✗ | Length of generated NanoID filename. | `12` |
| `S3_UPLOAD_LINK_EXPIRES_IN` | ✗ | Expiration time in seconds for uploaded object. | — |


## Skeleton Files (`skel/`)

Each skeleton is a Bash template that already sources `lib/bash/initrc`, enables `set -Eeuo pipefail`, provides help text with `#/` comments, and wires in the shared logging/prompt helpers.

- **`skel/bash/noargs`** - Minimal command pattern with `-h/--help` and optional `--verbose`, intended for scripts with no positional arguments
- **`skel/bash/args`** - Adds positional argument collection while preserving the common option parser
- **`skel/bash/params-args`** - Demonstrates combined flag, parameter, and positional handling (e.g. `--param value` plus extra arguments)
- **`skel/bash/cron-safe`** - Wraps execution with a file lock so cron jobs do not overlap
- **`skel/bash/daemon`** - Long-running loop with configurable interval and graceful shutdown handling
- **`skel/bash/fileproc`** - Processes files from arguments or stdin, creating a temporary work directory and supporting a dry-run mode
- **`skel/bash/interactive`** - Interactive workflow with prompts, optional non-interactive mode, and default handling
- **`skel/bash/net`** - HTTP client scaffold with retries, timeouts, and method/payload parameters using `curl`
- **`skel/bash/parallel`** - Executes tasks concurrently with a configurable job limit and failure tracking

## Script Creation

1. Run `bin/script-scaffold` from the repository root (or ensure `bin/` is on your `PATH`)
2. Choose a skeleton by number or name; press enter to accept the default first option
3. Supply a kebab-case script name (the helper enforces this) and a short description that replaces `{{ description }}` in the template
4. Enter the summary text when prompted. The tool writes the new script into `bin/`, marks it executable, and opens it in `$EDITOR`
5. Replace the `TODO` comments with your logic, keeping the `#/` documentation block accurate and the `set -Eeuo pipefail` directive intact
6. When the script reuses shared facilities, keep sourcing `../lib/bash/initrc` so you can call helpers such as `log.info`, `prompt.ask_yes_no`, `fs.mktmp`, `lock.acquire`, and `shell.defer`
7. Use `bin/bin-list-scripts` to confirm the description renders nicely and consider running `bin/file-mark-executable` if you edit a script outside of `script-scaffold`

#### Conventions to follow when authoring new scripts

- Keep filenames in kebab-case and store executables under `bin/` so `shell/bash/profile` adds them to the `PATH`
- Document usage with `#/` comment lines at the top so `script.usage` can emit help text automatically
- Prefer the common option parsing helpers (`script.parse_common` or the patterns shown in the skeletons) to deliver consistent `-h/--help` and `-v/--verbose` behaviour
- Use the logging (`log.info`, `log.warn`, `log.error`), prompting, locking, and filesystem helpers from `lib/bash/initrc` instead of reimplementing them
- When creating new media or conversion scripts, follow the examples that operate on the current working directory and respect standard tools such as ffmpeg or svgo

### Machine-specific Shell Hooks

`lib/bash/runtime` introduces `when.my_machine`, a guard that only runs its command list when `~/.machine_id` matches the current Mac's hardware UUID (queried via `ioreg`). `setup/macos/mac-provision` writes that file during provisioning, and `shell/bash/profile` uses it to add private content such as `~/.bin/personal`:

```bash
when.my_machine sys.path.append "$HOME/.bin/personal"
```

If you bootstrap a new host outside the provisioner, populate `~/.machine_id` manually with `ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}'` so the guard succeeds on that machine.
