# FS Module Reference

Filesystem helpers from `lib/bash/fs` for inspecting and manipulating paths.

## `fs.isdir`
Checks whether a path is an existing directory.

```bash
fs.isdir /tmp && echo "Directory exists"
```

```text
Directory exists
```

## `fs.isfile`
Checks whether a path is an existing regular file.

```bash
tmp_file="/tmp/fs-example.txt"
printf 'demo' >"$tmp_file"
fs.isfile "$tmp_file" && echo "Regular file"
rm "$tmp_file"
```

```text
Regular file
```

## `fs.exists`
Checks for the existence of any filesystem entry (file, directory, symlink, etc.).

```bash
fs.exists /etc/passwd && echo "Path found"
```

```text
Path found
```

## `fs.file_size_bytes`
Prints the size of a file in bytes, honoring platform-specific `stat`.

```bash
printf 'hello' > /tmp/fs-size.txt
fs.file_size_bytes /tmp/fs-size.txt
rm /tmp/fs-size.txt
```

```text
5
```

## `fs.mkcd`
Creates a directory (including parents) and changes into it.

```bash
fs.mkcd /tmp/project-build && pwd
```

```text
/tmp/project-build
```

## `fs.touchp`
Ensures parent directories exist and touches a file.

```bash
fs.touchp /tmp/logs/app/output.log
fs.isfile /tmp/logs/app/output.log && echo "File created"
```

```text
File created
```

## `fs.mktmp`
Creates a temporary file or directory with an optional prefix.

```bash
tmp_dir=$(fs.mktmp dir deploy)
printf 'Temp dir: %s\n' "$tmp_dir"
```

```text
Temp dir: /tmp/deploy.ABC123
```

## `fs.extract`
Extracts common archive formats using `tar`, `unzip`, `unrar`, or `7z`.

```bash
fs.extract archive.tar.gz
```

```text
# no output on success (extractors print filenames if verbose)
```

## `file.expand_globs`
Expands glob patterns in-place for an array of paths.

```bash
paths=("docs/*.md")
file.expand_globs paths
printf '%s\n' "${paths[@]}"
```

```text
docs/ai.md
docs/alias.md
docs/array.md
docs/aws.md
docs/cache.md
docs/fmt.md
docs/fs.md
docs/http.md
```
