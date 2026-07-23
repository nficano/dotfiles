# Dotfiles

This repository collects personal macOS/Linux dotfiles, provisioning scripts, and helper utilities. The layout keeps shell configuration, application profiles, and executable helpers in discrete directories while sharing a common Bash library for reusable behaviour.

## Repository Organization

- **`bin/`** - Executable utilities referenced below; symlinked into `~/.bin` by `make setup-tree`
- **`home/`** - Version-controlled copies of dotfiles such as `gitconfig`, `tmux.conf`, and `pip.conf`; `make setup-tree` links them into `$HOME`
- **`lib/`** - Shared shell libraries. `lib/bash/initrc` bootstraps a Python-inspired stdlib composed of modules like `logging`, `strings`, `os`, `runtime`, and `ui/core`. Scripts import that aggregator for logging, prompting, filesystem helpers, deferred sourcing, locking, and other primitives.
- **`profiles/`** - Application-specific settings, currently an iTerm2 profile in `profiles/iterm2/profile.json`
- **`setup/`** - Provisioning data. `setup/macos/Brewfile` captures brew dependencies, `setup/macos/defaults.conf` records macOS `defaults`, and `setup/macos/dock.conf` records Dock layout. The `mac-provision` script that consumed these was removed and is pending a rewrite.
- **`shell/`** - Interactive shell entrypoints. `shell/bash/profile` bootstraps the full lib stdlib for interactive use; `shell/bash/bashrc` is a portable, dependency-free rc file for servers.
- **`Makefile`** - Convenience tasks: `make setup-tree` prepares directories and symlinks in the home directory, and the `deploy-*` targets bump the version tag. (`make install` currently only runs `setup-tree`; provisioning is pending the `mac-provision` rewrite.)

## macOS Provisioning

> **Status:** the `mac-provision` script was removed and is being rewritten. The data it consumed still lives in `setup/macos/`: `Brewfile` (+ `Brewfile.lock.json`), `defaults.conf` (`domain|key|type|value`), and `dock.conf`. `make create-brewfile` still regenerates the Brewfile from the current system.

## bin/ Utilities

### Shell and Workflow Helpers

- **`bash-completions-compile`** - Compiles the ~236 scripts in `$BREW_PREFIX/etc/bash_completion.d` into a lazy-loading cache (`~/.cache/dotfiles/completions.bash`) so interactive shells register lightweight stubs and each completion loads on first `<Tab>`; the profile re-runs it automatically when the directory changes
- **`bin-list-scripts`** - Lists every file in `~/.bin` and prints the second line of each script as its description, making it easy to discover available helpers
- **`file-mark-executable`** - Wraps `chmod +x` so you can make a new script executable with `file-mark-executable path/to/script`
- **`file-metadata`** - Delegates to `mdls` on macOS or `mediainfo` elsewhere to inspect file metadata
- **`file-permissions`** - Shows a file or directory's permissions in symbolic and octal form (`file-permissions /usr/bin`)
- **`finder-front-path`** - Uses AppleScript to print the path of the frontmost Finder window, allowing quick `cd "$(finder-front-path)"`
- **`history-grep`** - Greps the Bash history file with regex matching while de-duplicating results, handy for retrieving past commands
- **`path-print`** - Pretty-prints the `PATH` environment variable one entry per line to confirm search order
- **`shell-add-alias`** - Appends an alias definition to `~/.bash_profile` and reminds you to reload it; run `shell-add-alias -n gs -c "git status"` to register shortcuts without editing the file manually
- **`trash`** - Moves files or directories to the macOS Trash instead of deleting them, with optional confirmation flags (`t -i big-file`)

### File and Directory Tools

- **`s3-upload-and-link`** - Upload files to S3 and copy the shareable URL to the clipboard (similar to CloudApp)
- **`cppath`** - Resolves a file or directory path and copies it to the clipboard
- **`path-resolve`** - Resolves a relative path to an absolute path (`path-resolve ../some/file`)
- **`path-expand-tilde`** - Expands a path containing `~` to its real location (`path-expand-tilde ~/Downloads`)
- **`find-copy-matches`** - Recursively finds files matching a glob and copies them to a destination (`find-copy-matches "*.svg" ~/vectors`)
- **`find-move-matches`** - Same as above but moves matched files (`find-move-matches "*.log" archive/`)
- **`find-extension`** - Lists files with a given extension under the current tree[^1]
- **`find-filename`** - Recurses for exact filename matches (`find-filename "*.plist"`)[^1]
- **`find-directory`** - Recursively finds directories by name (`find-directory build`)

[^1]: I gave up trying to remember `find` syntax.

### Media and Asset Pipelines

- **`this-to-that`** - Best-quality file format conversions powered by ffmpeg (and friends)
- **`adobe-font-export`** - Extracts Adobe Creative Cloud fonts from CoreSync, optionally converting them to TTF or WOFF2 via FontForge/woff2 before copying them out
- **`font-backup`** - Backs up and restores user fonts using compressed tar archives
- **`fa-icon-downloader`** - Downloads Font Awesome SVG icons using an npm token
- **`exif-copy-tags`** - Copies all EXIF metadata from one file to another via `exiftool`, useful when transcoding media

### System, macOS, and Services

- **`clean-up-open-with-menu`** - Rebuilds LaunchServices registrations and restarts Finder to clear duplicate "Open With" entries
- **`docker-wipe-all`** - Stops and removes all Docker containers, images, volumes, networks, and build cache after an explicit confirmation
- **`finder-hide-desktop` / `finder-show-desktop`** - Toggle Finder desktop icon visibility
- **`macos-dns-flush`** - Flushes DNS caches via `dscacheutil` and `mDNSResponder`
- **`macos-hostname-set`** - Updates the system hostname, LocalHostName, and related SMB settings in one step

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

### Development and Miscellaneous

- **`ansi-code`** - Inspect and compose ANSI SGR escape sequences
- **`time-epoch`** - Prints the current Unix epoch timestamp
- **`nanoid`** - Generate short, URL-safe unique IDs

## Spell Correct

`spell-correct' is spell check and correction utility that uses ChatGPT for spelling correction.

**Usage**

```bash
spell-correct leasure
# Copied correction "leisure" to the clipboard
```

#### Environment Variables

| Name                               | Required | Description                                  | Default       |
| ---------------------------------- | -------- | -------------------------------------------- | ------------- |
| `OPENAI_API_KEY`                   | ✓        | Your OpenAI API key used for authentication. | —             |
| `SPELL_CORRECT_OPENAI_MODEL`       | ✗        | Model used for correction.                   | `gpt-4o-mini` |
| `SPELL_CORRECT_OPENAI_AGENT`       | ✗        | Agent name defined in `.agents` file.        | `spell-check` |
| `SPELL_CORRECT_OPENAI_TEMPERATURE` | ✗        | Controls randomness of model output.         | `0`           |

---

### Autoflags

`autoflags` converts natural language intents into safe shell commands. _(Work in progress.)_

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

| Name                           | Required | Description                                                 | Default       |
| ------------------------------ | -------- | ----------------------------------------------------------- | ------------- |
| `OPENAI_API_KEY`               | ✓        | Your OpenAI API key used for authentication.                | —             |
| `AUTOFLAGS_YES`                | ✗        | Run without confirmation prompt.                            | `false`       |
| `AUTOFLAGS_PRINT`              | ✗        | Show suggested command without executing.                   | `false`       |
| `AUTOFLAGS_COPY`               | ✗        | Copy command to clipboard (implies `AUTOFLAGS_PRINT=true`). | `false`       |
| `AUTOFLAGS_ALLOW_ALT`          | ✗        | Allow AI to suggest alternate tools or commands.            | —             |
| `AUTOFLAGS_CONFIRM_DEFAULT`    | ✗        | Default answer when prompted (Y or N).                      | `N`           |
| `AUTOFLAGS_REQUIRE_WHICH`      | ✗        | Verify that suggested alternative command exists.           | `false`       |
| `AUTOFLAGS_NO_CLIPBOARD`       | ✗        | Disable automatic clipboard copy.                           | `false`       |
| `AUTOFLAGS_CONTEXT`            | ✗        | Add extra context to AI prompt.                             | —             |
| `AUTOFLAGS_OPENAI_MODEL`       | ✗        | Model used for generation.                                  | `gpt-4o-mini` |
| `AUTOFLAGS_OPENAI_AGENT`       | ✗        | Agent name defined in `.agents` file.                       | `autoflags`   |
| `AUTOFLAGS_OPENAI_TEMPERATURE` | ✗        | Controls randomness of model output.                        | `0`           |

---

### s3-upload-and-link

Uploads a file to S3 and copies the shareable URL to your clipboard.

**Usage**

```bash
s3-upload-and-link ubuntu-24.04.3-desktop-amd64.iso
# https://s3.us-east-1.amazonaws.com/mybucket/9oe3HVzO.iso
```

#### Environment Variables

| Name                           | Required | Description                                        | Default       |
| ------------------------------ | -------- | -------------------------------------------------- | ------------- |
| `S3_UPLOAD_LINK_BUCKET`        | ✓        | S3 bucket name (supports optional `s3://` prefix). | —             |
| `S3_UPLOAD_LINK_PREFIX`        | ✗        | Optional key prefix for uploaded objects.          | —             |
| `S3_UPLOAD_LINK_URL_BASE`      | ✗        | Base HTTPS URL used to construct share links.      | —             |
| `S3_UPLOAD_LINK_BUCKET_REGION` | ✗        | Region used for default URL generation.            | —             |
| `S3_UPLOAD_LINK_ACL`           | ✗        | ACL for `aws s3 cp`.                               | `public-read` |
| `S3_UPLOAD_LINK_CACHE_CONTROL` | ✗        | `Cache-Control` header for uploaded object.        | —             |
| `S3_UPLOAD_LINK_CONTENT_TYPE`  | ✗        | Explicit `Content-Type` override.                  | —             |
| `S3_UPLOAD_LINK_ID_LENGTH`     | ✗        | Length of generated NanoID filename.               | `12`          |
| `S3_UPLOAD_LINK_EXPIRES_IN`    | ✗        | Expiration time in seconds for uploaded object.    | —             |

## Script Conventions

- Keep filenames in kebab-case and store executables under `bin/` so `shell/bash/profile` adds them to the `PATH`
- Document usage with `#/` comment lines at the top so `script.usage` can emit help text automatically
- Use the logging (`log.info`, `log.warn`, `log.error`), prompting, locking, and filesystem helpers from `lib/bash/initrc` instead of reimplementing them
- Run `bin/bin-list-scripts` to confirm a new script's description (second line) renders nicely, and `bin/file-mark-executable` if you need to mark it executable

### Machine-specific Shell Hooks

`lib/bash/runtime` introduces `when.my_machine`, a guard that only runs its command list when `~/.machine_id` matches the current Mac's hardware UUID (queried via `ioreg`). Populate that file with the command shown below (the old provisioner used to write it), and `shell/bash/profile` uses it to add private content such as `~/.bin/personal`:

```bash
when.my_machine sys.path.append "$HOME/.bin/personal"
```

If you bootstrap a new host outside the provisioner, populate `~/.machine_id` manually with `ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}'` so the guard succeeds on that machine.
