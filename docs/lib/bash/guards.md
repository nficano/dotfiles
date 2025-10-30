# Exceptions & Guards Reference

Examples assume the repository root as the working directory so the modules can
be sourced via `lib/bash/<module>`.

```bash
source "lib/bash/guards"
```

### `guards.raise`

Raise an exception (using the exceptions module when available).

```bash
[[ -n ${API_TOKEN:-} ]] || guards.raise NameError "API_TOKEN missing" 120
```

### `guards.nonempty`

Require a value to be non-empty.

```bash
guards.nonempty "$username" "username"
```

### `guards.is_int`

Check whether a value is an integer (exit status only).

```bash
if guards.is_int "$retries"; then
  printf 'Retry count ok\n'
else
  printf 'Retry count invalid\n'
fi
```

### `guards.require_int`

Ensure a value parses as an integer.

```bash
guards.require_int "$PORT" "PORT"
```

### `guards.is_uint`

Check whether a value is an unsigned integer.

```bash
if guards.is_uint "$threads"; then
  echo "Threads: $threads"
fi
```

### `guards.require_uint`

Require an unsigned integer.

```bash
guards.require_uint "$MAX_CLIENTS" "MAX_CLIENTS"
```

### `guards.require_bool`

Accept truthy/falsey values such as `yes/no` or `0/1`.

```bash
guards.require_bool "$AUTO_APPROVE" "AUTO_APPROVE"
```

### `guards.require_range`

Ensure a numeric value is inside an inclusive range.

```bash
guards.require_range "$timeout" 1 30 "timeout (minutes)"
```

### `guards.require_file`

Assert a path exists and is a regular file.

```bash
guards.require_file "$HOME/.ssh/config"
```

### `guards.require_dir`

Assert a directory exists.

```bash
guards.require_dir "/var/log/myapp"
```

### `guards.require_readable`

Check read permissions for a path.

```bash
guards.require_readable "$credentials"
```

### `guards.require_writable`

Check write permissions for a path.

```bash
guards.require_writable "$output_dir"
```

### `guards.require_executable`

Require execute permissions on a path.

```bash
guards.require_executable "$script_path"
```

### `guards.require_exec`

Ensure a command is available on `PATH`.

```bash
guards.require_exec "jq"
```

### `guards.require_vars`

Verify multiple environment variables are set and non-empty.

```bash
guards.require_vars AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
```

### `guards.require_matches`

Validate a value against a regular expression.

```bash
guards.require_matches "$version" '^v[0-9]+\.[0-9]+\.[0-9]+$' "version"
```

### `guards.require_oneof`

Ensure a value is within a pipe-delimited set.

```bash
guards.require_oneof "$LEVEL" "debug|info|warn|error" "LOG_LEVEL"
```

### `guards.require_url`

Perform a lightweight URL validation.

```bash
guards.require_url "$API_ENDPOINT" "API_ENDPOINT"
```

> For block-level error handling, prefer `exception.guard begin|end`.
