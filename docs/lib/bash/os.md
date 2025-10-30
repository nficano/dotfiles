# OS Module Reference

Platform helpers from `lib/bash/os` and `sys.*` shims.

## `os.devnull`
Runs a command while discarding stdout and stderr.

```bash
os.devnull ls /tmp
```

```text
# no output; command exit status is preserved
```

## `os.setenv`
Sets an environment variable for the current shell.

```bash
os.setenv MY_FLAG enabled
echo "$MY_FLAG"
```

```text
enabled
```

## `os.getenv`
Retrieves an environment variable value (empty when unset).

```bash
os.setenv DEMO_VALUE "42"
os.getenv DEMO_VALUE
```

```text
42
```

## `sys.platform`
Returns the lowercase platform name from `uname -s`.

```bash
sys.platform
```

```text
darwin
```

## `os.platform.is_darwin`
Succeeds on macOS systems.

```bash
if os.platform.is_darwin; then
  echo "Running on macOS"
fi
```

```text
Running on macOS
```

## `os.platform.is_linux`
Succeeds on Linux systems.

```bash
os.platform.is_linux || echo "Not Linux"
```

```text
Not Linux
```

## `os.path.exists`
Checks if a regular file exists at the given path.

```bash
printf 'demo' >/tmp/os-file.txt
os.path.exists /tmp/os-file.txt && echo "File found"
```

```text
File found
```

## `sys.path.contains`
Reports success when a command is discoverable in `PATH`.

```bash
if sys.path.contains git; then
  echo "git is available"
fi
```

```text
git is available
```

## `sys.path.prepend`
Adds a directory to the front of `PATH` if it exists.

```bash
sys.path.prepend /usr/local/bin
echo "$PATH" | cut -d: -f1
```

```text
/usr/local/bin
```

## `sys.path.append`
Adds a directory to the end of `PATH` if it exists.

```bash
sys.path.append /usr/local/sbin
echo "$PATH" | tr ':' '\n' | tail -n1
```

```text
/usr/local/sbin
```

## `sys.path.prepend_many`
Prepends multiple directories in order.

```bash
sys.path.prepend_many "$HOME/bin" "/opt/tools"
echo "$PATH" | cut -d: -f1-2
```

```text
/Users/alice/bin:/opt/tools
```

## `sys.path.append_many`
Appends multiple directories in order.

```bash
sys.path.append_many "/opt/helpers" "/opt/extras"
echo "$PATH" | tr ':' '\n' | tail -n2
```

```text
/opt/helpers
/opt/extras
```

## `clip.copy`
Copies stdin to the system clipboard (uses `pbcopy` on macOS or `xclip` on Linux).

```bash
printf 'Copied text' | clip.copy
```

```text
# no output; clipboard now contains "Copied text"
```

## `clip.paste`
Prints the current clipboard contents.

```bash
clip.paste
```

```text
Copied text
```

## `os.machine_id.matches_current`
Checks whether `~/.machine_id` matches the current hardware UUID (macOS only).

```bash
if os.machine_id.matches_current; then
  echo "Machine ID matches"
else
  echo "Machine ID mismatch"
fi
```

```text
Machine ID matches
```

## `os.on_battery_power`
Returns success when the machine is currently running on battery.

```bash
if os.on_battery_power; then
  echo "On battery"
else
  echo "On AC power"
fi
```

```text
On AC power
```
