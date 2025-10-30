# Script Module Reference

CLI convenience helpers from `lib/bash/script`.

## `script.usage`
Prints the calling script's `#/` help lines and exits with the given status.

```bash
cat <<'EOF' >/tmp/demo.sh
#!/usr/bin/env bash
#/ Usage: demo.sh [options]
#/   -h  Show help
script.usage 0
EOF
bash /tmp/demo.sh
```

```text
Usage: demo.sh [options]
  -h  Show help
```

## `script.cleanup`
Clears standard traps (SIGINT, SIGTERM, ERR, EXIT).

```bash
trap 'echo interrupted' SIGINT
script.cleanup
trap -p SIGINT
```

```text
# no trap remains; command prints nothing
```

## `script.parse_common`
Normalizes `--help`/`--verbose` and passes through the remaining arguments.

```bash
set -- --verbose -- input.txt
parsed=$(script.parse_common "$@")
echo "$parsed"
```

```text
-v -- input.txt
```

## `script.parse_with_opts`
Maps long options into short equivalents for `getopts`.

```bash
set -- --file=demo.txt
parsed=$(script.parse_with_opts ':hvf:' --long file=f -- "$@")
echo "$parsed"
```

```text
-f demo.txt
```

## `script.validate_positive_int`
Ensures a numeric option is a positive integer.

```bash
script.validate_positive_int 5 "retry count"
```

```text
# no output when the value is valid
```

## `script.require_args`
Ensures a minimum number of positional arguments are supplied.

```bash
set -- username
script.require_args 2 "username and password" "$@" || echo "Missing args"
```

```text
Missing args
```
