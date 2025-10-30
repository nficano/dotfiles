# Paths Module Reference

Path manipulation helpers from `lib/bash/paths`. Internal `_path__*` helpers are omitted.

## `path.strip_trailing_slashes`
Removes redundant trailing slashes (except for `/` itself).

```bash
path.strip_trailing_slashes "/usr/local///"
```

```text
/usr/local
```

## `path.join`
Joins path segments, avoiding duplicate separators.

```bash
path.join "/usr" "local/bin" "../share"
```

```text
/usr/local/bin/../share
```

## `path.dirname`
Returns the directory portion of a path.

```bash
path.dirname "/usr/local/bin/python"
```

```text
/usr/local/bin
```

## `path.basename`
Returns the final component of a path.

```bash
path.basename "/usr/local/bin/python"
```

```text
python
```

## `path.name`
Alias of `path.basename`.

```bash
path.name "/tmp/archive.tar.gz"
```

```text
archive.tar.gz
```

## `path.parent`
Gets the parent directory, falling back to `.`.

```bash
path.parent "notes/today.md"
```

```text
notes
```

## `path.stem`
Returns the filename without its final suffix.

```bash
path.stem "/tmp/archive.tar.gz"
```

```text
archive.tar
```

## `path.suffix`
Returns the final suffix (including the dot) or empty string.

```bash
path.suffix "/tmp/archive.tar.gz"
```

```text
.gz
```

## `path.suffixes`
Lists all suffixes joined by spaces.

```bash
path.suffixes "/tmp/archive.tar.gz"
```

```text
.tar .gz
```

## `path.with_name`
Replaces the final path component with a new name.

```bash
path.with_name "/tmp/archive.tar.gz" "manifest.json"
```

```text
/tmp/manifest.json
```

## `path.with_suffix`
Changes (or removes) the final suffix.

```bash
path.with_suffix "/tmp/archive.tar.gz" ".zip"
```

```text
/tmp/archive.tar.zip
```

## `path.parts`
Emits NUL-separated path parts; useful with a read loop.

```bash
while IFS= read -r -d '' part; do
  printf '[%s]\n' "$part"
done < <(path.parts "/usr/local/bin")
```

```text
[/]
[usr]
[local]
[bin]
```

## `path.isabs`
Indicates if a path is absolute (prints `1`/`0` and returns success/failure).

```bash
path.isabs "/usr/local"
```

```text
1
```

## `path.exists`
Returns success when the path exists.

```bash
touch /tmp/path-exists.txt
path.exists /tmp/path-exists.txt && echo "Exists"
```

```text
Exists
```

## `path.isfile`
Checks for a regular file.

```bash
path.isfile /tmp/path-exists.txt && echo "File"
```

```text
File
```

## `path.isdir`
Checks for a directory.

```bash
mkdir -p /tmp/path-demo
path.isdir /tmp/path-demo && echo "Directory"
```

```text
Directory
```

## `path.expand_env`
Expands `$HOME` and `${HOME}` placeholders.

```bash
path.expand_env "\$HOME/projects"
```

```text
/Users/alice/projects
```

## `path.expand_user`
Expands leading `~` to the current home directory.

```bash
path.expand_user "~/Downloads"
```

```text
/Users/alice/Downloads
```

## `path.expand`
Applies both environment and user expansion.

```bash
path.expand "\$HOME/Documents"
```

```text
/Users/alice/Documents
```

## `path.absolute`
Normalizes a path relative to the current working directory without resolving symlinks.

```bash
(cd /usr/local && path.absolute "../bin")
```

```text
/usr/bin
```

## `path.resolve`
Resolves a path (expanding env/user, handling symlinks when possible).

```bash
path.resolve "../README.md" "$PWD/docs"
```

```text
/Users/alice/docs/../README.md
```

## `path.pattern_to_glob`
Normalizes a glob pattern relative to an optional base directory.

```bash
path.pattern_to_glob "*.md" "$PWD/docs"
```

```text
/Users/alice/project/docs/*.md
```

## `path.is_excluded`
Checks if a candidate matches any ignore patterns.

```bash
patterns=("build" "node_modules")
if path.is_excluded "project/node_modules/pkg" "project" patterns; then
  echo "Excluded"
fi
```

```text
Excluded
```

## `path.backup_label`
Builds a backup-friendly label for a file relative to `$HOME` or root.

```bash
path.backup_label "$HOME/Documents/report.pdf"
```

```text
home/alice/Documents/report.pdf
```

## `path.cwd`
Prints the current working directory.

```bash
path.cwd
```

```text
/Users/alice/project
```

## `path.home`
Prints the current user's home directory.

```bash
path.home
```

```text
/Users/alice
```

## `path.mkdir`
Creates a directory (supports `-p`).

```bash
path.mkdir -p /tmp/path-tree/subdir
ls /tmp/path-tree
```

```text
subdir
```

## `path.unlink`
Removes a file if it exists.

```bash
printf 'remove me' >/tmp/path-remove.txt
path.unlink /tmp/path-remove.txt
path.exists /tmp/path-remove.txt || echo "File removed"
```

```text
File removed
```

## `path.iterdir`
Lists entries directly within a directory.

```bash
path.iterdir /tmp/path-tree
```

```text
/tmp/path-tree/subdir
```

## `path.stat.size`
Prints the size of a path in bytes.

```bash
printf 'hello' >/tmp/path-size.txt
path.stat.size /tmp/path-size.txt
```

```text
5
```

## `path.match`
Performs a case-insensitive glob match.

```bash
if path.match "src/Readme.MD" "*/readme.md"; then
  echo "Match"
fi
```

```text
Match
```
