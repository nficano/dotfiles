# Runtime Module Reference

Execution-flow helpers provided by `lib/bash/runtime`.

## `when.cmd`
Runs a callback only when the given tool exists.

```bash
when.cmd git echo "git detected"
```

```text
git detected
```

## `when.not_cmd`
Runs a callback only when the tool is missing.

```bash
when.not_cmd foobinary echo "foobinary not installed"
```

```text
foobinary not installed
```

## `when.darwin`
Executes a command when running on macOS.

```bash
when.darwin echo "macOS-specific setup"
```

```text
macOS-specific setup
```

## `when.linux`
Executes a command when running on Linux.

```bash
when.linux echo "linux-specific setup" || echo "Not Linux"
```

```text
Not Linux
```

## `when.my_machine`
Runs a command only when the stored machine UUID matches the current host.

```bash
when.my_machine echo "This is my personal machine" || echo "Different host"
```

```text
Different host
```

## `run.maybe`
Logs and skips commands when `dry_run` is set.

```bash
run.maybe 1 "Restarting service" sudo systemctl restart demo
```

```text
[INFO] [dry-run] Restarting service
[INFO]           sudo systemctl restart demo
```

## `require.cmd`
Verifies that each named command exists, logging errors otherwise.

```bash
require.cmd git bash || echo "Missing dependencies"
```

```text
# no output when all commands exist
```

## `ensure.cmds`
Ensures that commands are installed (supports `cmd:formula` specs on macOS).

```bash
ensure.cmds "bash" "git:git"
```

```text
# exits 0 when every command is already available
```

## `retry`
Retries a command with linear backoff.

```bash
attempt=0
retry 3 1 '((attempt++ < 2)) && { echo "try $attempt"; false; } || { echo "try $attempt"; true; }'
```

```text
try 1
try 2
try 3
```
