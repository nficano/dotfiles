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

Scripts follow a **`domain-action`** naming convention (domain noun first, so `net<Tab>`, `path<Tab>`, `file<Tab>` group related tools). Related helpers are consolidated into **dispatcher tools** that take a subcommand. Every command has tab-completion, registered by `shell/bash/completions`. Old names still work via compatibility aliases in `shell/bash/profile` (a clearly-marked block you can delete once retrained).

**Discovery** — type `?` for a colorful column list of every command, or `??` for an aligned name + description table. `?`/`??` also act as launchers with delegated completion: `? <Tab>` completes command names, and each subsequent `<Tab>` reveals the chosen command's own completion (`? net <Tab>` → net's subcommands). Defined in `shell/bash/query`.

**Portability** — scripts detect the OS and degrade gracefully via `lib/bash/deps`. Tools that can't run on the current OS print why and exit cleanly (`os.require_macos`); missing dependencies are explained and, on an interactive terminal, offered for one-key install via the detected package manager (`brew`/`apt`/`dnf`/`pacman`/`zypper`/`apk`) through `deps.require`/`deps.need`. `trash` uses the macOS Trash on macOS and `gio trash`/`trash-cli` on Linux.

### Dispatchers (multi-command tools)

- **`net`** - Network diagnostics: `net info` (interfaces, gateways, DNS, public IP), `net listeners` (listening ports by process), `net ttfb <url>` (DNS/TCP/TLS/TTFB timing), `net check-host <file>` (URLs returning HTTP 200), `net check-port <host> <port>`, `net port-pid <port>`
- **`ff`** - Filesystem search (named `ff`, not `find`, to avoid shadowing): `ff name <pattern>`, `ff ext <extension>`, `ff dir <name>`, `ff copy <expr> <dest>`, `ff move <expr> <dest>`
- **`path`** - Path helpers: `path resolve <p>`, `path expand <p>`, `path env` (print `$PATH`), `path copy <p> [-r|-H|-b]` (copy to clipboard; the profile wraps `path` so `-b/--back` can cd the parent shell)
- **`finder`** - Finder: `finder path` (frontmost window path — `f` alias does `cd "$(finder path)"`), `finder desktop-hide`, `finder desktop-show`
- **`proc`** - Processes: `proc kill <pid>` (SIGTERM), `proc kill --port <port>` (kill listener on a TCP port). `proc list` is a scaffold placeholder (not yet implemented).
- **`mac`** - macOS maintenance: `mac dns-flush`, `mac hostname <name>` (scutil + SMB NetBIOS), `mac openwith-reset` (rebuild LaunchServices "Open With")
- **`font`** - Fonts: `font backup [-o file]`, `font restore <source>` (local path or URL), `font adobe-export <font> [dir] [--ttf|--woff2]`

### Standalone helpers

- **`bin-list`** - Lists every file in `~/.bin` with its second-line description
- **`shell-completions-compile`** - Compiles `$BREW_PREFIX/etc/bash_completion.d` into a lazy-loading cache so each completion loads on first `<Tab>`; the profile re-runs it when the directory changes
- **`shell-alias-add`** - Appends an alias to `~/.bash_profile` (`shell-alias-add -n gs -c "git status"`)
- **`shell-history-grep`** - Regex-greps the Bash history file, de-duplicating results
- **`file-info`** - File metadata via `mdls` (macOS) or `mediainfo`
- **`file-perms`** - Symbolic and octal permissions for a file or directory
- **`file-chmodx`** - `chmod +x` wrapper to mark scripts executable
- **`http-headers`** - Fetches only HTTP response headers for a URL (`curl -sv`)
- **`media-convert`** - Best-quality file-format conversions powered by ffmpeg (and friends)
- **`img-exif-copy`** - Copies EXIF metadata from one file to another via `exiftool`
- **`icon-fa-fetch`** - Downloads Font Awesome SVG icons using an npm token
- **`term-ansi`** - Inspect and compose ANSI SGR escape sequences
- **`text-spell`** - Spell-check/correct utility that uses ChatGPT
- **`s3-upload`** - Upload a file or clipboard text to S3 and copy the shareable URL to the clipboard
- **`docker-wipe`** - Removes all Docker containers, images, volumes, networks, and build cache after confirmation
- **`time-epoch`** - Prints the current Unix epoch timestamp
- **`nanoid`** - Generate short, URL-safe unique IDs
- **`trash`** - Moves files/directories to the macOS Trash instead of deleting

## text-spell

`text-spell` is a spell-check and correction utility that uses ChatGPT.

**Usage**

```bash
text-spell leasure
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

### s3-upload

Uploads a file or text from your clipboard to S3, then copies the shareable URL to your clipboard.

**Usage**

```bash
s3-upload ubuntu-24.04.3-desktop-amd64.iso
# https://s3.us-east-1.amazonaws.com/mybucket/9oe3HVzO.iso

s3-upload --clipboard
# Uploads the clipboard as clipboard.txt

s3-upload --clipboard --name snippet.json
# Uploads the clipboard with a .json extension

s3-upload --trash ~/Documents/Screenshots/Screenshot.png
# Copies the URL, then moves the local file to Trash
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
| `S3_UPLOAD_LINK_CONTENT_TYPE`  | ✗        | Explicit `Content-Type` override.                  | `text/plain; charset=utf-8` for clipboard text |
| `S3_UPLOAD_LINK_ID_LENGTH`     | ✗        | Length of generated NanoID filename.               | `12`          |
| `S3_UPLOAD_LINK_EXPIRES_IN`    | ✗        | HTTP expiration time in seconds.                   | `86400`       |
| `S3_UPLOAD_LINK_NO_LIFECYCLE`  | ✗        | Skip the `s3-upload-ttl=24h` lifecycle tag.         | `0`           |

Uploads are tagged with `s3-upload-ttl=24h`. The matching S3 bucket lifecycle rule deletes tagged objects after one day; HTTP `Expires` metadata alone does not delete an object.

#### Screenshot Folder Action

The `Upload screenshots to S3` Automator Folder Action watches `~/Documents`, filters for macOS screenshots, uploads each one, explicitly sets the system clipboard to its S3 URL, and only then moves the local image to Trash. Other files in Documents are ignored.

## Script Conventions

- Keep filenames in kebab-case and store executables under `bin/` so `shell/bash/profile` adds them to the `PATH`
- Document usage with `#/` comment lines at the top so `script.usage` can emit help text automatically
- Use the logging (`log.info`, `log.warn`, `log.error`), prompting, locking, and filesystem helpers from `lib/bash/initrc` instead of reimplementing them
- Run `bin-list` (or `??`) to confirm a new script's description (second line) renders nicely, and `file-chmodx` if you need to mark it executable
- Gate OS-specific tools with `os.require_macos`/`os.require_linux` and declare external dependencies with `deps.require`/`deps.need` (from `lib/bash/deps`) so scripts degrade gracefully and offer to install what's missing

### Machine-specific Shell Hooks

`lib/bash/runtime` introduces `when.my_machine`, a guard that only runs its command list when `~/.machine_id` matches the current Mac's hardware UUID (queried via `ioreg`). Populate that file with the command shown below (the old provisioner used to write it), and `shell/bash/profile` uses it to add private content such as `~/.bin/personal`:

```bash
when.my_machine sys.path.append "$HOME/.bin/personal"
```

If you bootstrap a new host outside the provisioner, populate `~/.machine_id` manually with `ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}'` so the guard succeeds on that machine.

### Shell History

History is **append-only and shared**. `HISTFILE` stays at the conventional `~/.bash_history`, which `make setup-tree` symlinks to `~/Dropbox/system/bash_history` (seeding it from any existing history) so every session on every machine appends to one file. Each prompt runs `history -a` (flush this session's new lines) and `history -n` (pull in other sessions' lines) via `shell.setup_tab_safe_history`, and `shopt -s histappend` guarantees the file is never clobbered. On a host without Dropbox, `~/.bash_history` stays a normal local file.
