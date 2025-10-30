# Proc Module Reference

Process coordination helpers from `lib/bash/proc`.

## `proc.cpu_count`
Reports the number of online CPUs, falling back to 4.

```bash
proc.cpu_count
```

```text
8
```

## `proc.wait_for_pids`
Waits for background PIDs stored in an array and clears it, optionally setting a failure flag.

```bash
pids=()
sleep 0.1 &
pids+=("$!")
proc.wait_for_pids pids had_errors
echo "had_errors=$had_errors remaining=${#pids[@]}"
```

```text
had_errors=0 remaining=0
```

## `proc.capture_command`
Runs a command, capturing combined stdout/stderr into an array while exposing the exit status.

```bash
proc.capture_command captured status 0 bash -c 'echo out; echo err >&2'
printf 'status=%s lines=%s\n' "$status" "${#captured[@]}"
printf '%s\n' "${captured[@]}"
```

```text
status=0 lines=2
out
err
```

## `proc.interrupt_handler_init`
Configures global variables used by the interrupt handlers.

```bash
proc.interrupt_handler_init cleanup should_exit interrupted count \
  "[WARN] %s received; finishing work." \
  "[ERROR] Second %s received; exiting now." \
  99
```

```text
# no output; handler globals are updated
```

## `proc.handle_interrupt_signal`
Handles a named signal by incrementing a counter and printing the configured message.

```bash
proc.interrupt_handler_init cleanup should_exit interrupted count
proc.handle_interrupt_signal SIGINT
```

```text
[WARN] SIGINT received; finishing current work then exiting. Press Ctrl+C again to force quit.
```

> A second call for the same signal triggers the configured cleanup function (if any) and exits with the chosen code.

## `proc.handle_sigint`
Convenience wrapper that passes `"SIGINT"` to `proc.handle_interrupt_signal`.

```bash
proc.handle_sigint
```

```text
[WARN] SIGINT received; finishing current work then exiting. Press Ctrl+C again to force quit.
```

## `proc.handle_sigterm`
Convenience wrapper that passes `"SIGTERM"` to `proc.handle_interrupt_signal`.

```bash
proc.handle_sigterm
```

```text
[WARN] SIGTERM received; finishing current work then exiting. Press Ctrl+C again to force quit.
```
