# Exceptions & Guards Reference

Examples assume the repository root as the working directory so the modules can
be sourced via `lib/bash/<module>`.

```bash
source "lib/bash/exceptions"
```

## Exceptions Module

### `exception.register`

Register a new exception name/code pair so future raises preserve the numeric
exit status.

```bash
exception.register BackupError 180
exception.raise BackupError "rsync failed"
```

### `exception.code`

Look up the numeric code associated with an exception name.

```bash
code=$(exception.code FileNotFoundError)
printf 'FileNotFoundError exits with %s\n' "$code"
```

### `exception.name`

Convert an exit code into the canonical exception name.

```bash
exception.guard begin
false
exception.guard end || exception_name=$(exception.name "$?")
printf 'Last failure mapped to %s\n' "$exception_name"
```

### `exception.format`

Emit a formatted error line without raising.

```bash
exception.format ValueError "port must be numeric" 132
```

### `exception.raise`

Render and raise an exception. Honour `ERR_STRATEGY` (`return` or `exit`).

```bash
ERR_STRATEGY=return
if [[ ! -f "$1" ]]; then
  exception.raise FileNotFoundError "missing: $1"
fi
```

### `exception.wrap`

Run a command and raise a mapped exception when it fails.

```bash
exception.wrap OSError "copy %s -> %s" "$src" "$dst" -- cp "$src" "$dst"
```

### `exception.try` and `exception.as`

Use `exception.try` with `exception.as` to reclassify failures.

```bash
exception.guard begin
exception.try curl -fsS "$url" -o "$tmp" || exception.as ConnectionError "unable to reach $url"
exception.guard end
```

### `exception.guard`

Wrap blocks so unexpected errors are formatted consistently.

```bash
exception.guard begin
guards.require_file "$config" "config file"
source "$config"
exception.guard end
```
