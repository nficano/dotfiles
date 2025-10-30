# Logging Module Reference

Structured logging utilities from `lib/bash/logging` for consistent CLI feedback.

## `log.info`
Emits an informational message to stderr.

```bash
log.info "Starting sync"
```

```text
[INFO] Starting sync
```

## `log.warn`
Emits a warning message.

```bash
log.warn "Retrying after transient error"
```

```text
[WARN] Retrying after transient error
```

## `log.error`
Reports an error condition.

```bash
log.error "Failed to reach API"
```

```text
[ERR ] Failed to reach API
```

## `log.debug`
Outputs debug messages when `LOG_DEBUG` is set.

```bash
LOG_DEBUG=1 log.debug "Payload: ${payload}"
```

```text
[DBG] Payload: {...}
```

## `log.success`
Signals successful completion.

```bash
log.success "Deployment finished"
```

```text
[OK  ] Deployment finished
```

## `log.block_start`
Begins a structured log block, increasing indentation depth.

```bash
log.block_start "Build"
```

```text
[INFO] Build
```

## `log.block`
Prints an indented message within the current block.

```bash
log.block "Compiling assets"
```

```text
│  Compiling assets
```

## `log.block_end`
Closes the current block level, reducing indentation.

```bash
log.block_end
```

```text
# no output; subsequent block messages move up one level
```
