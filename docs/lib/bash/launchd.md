# Launchd Module Reference

Functions delivered by `lib/bash/launchd` to manage macOS `launchd` agents.

## `launchd.require_tooling`
Verifies that `launchctl` is available before attempting other actions.

```bash
launchd.require_tooling
```

```text
# exits 0 when launchctl exists; emits "launchctl is required..." otherwise
```

## `launchd.user_domain`
Returns the per-user launchd domain identifier (`gui/<uid>`).

```bash
launchd.user_domain
```

```text
gui/501
```

## `launchd.agent_plist_path`
Builds the plist path under `~/Library/LaunchAgents` for a given label.

```bash
launchd.agent_plist_path "com.example.job"
```

```text
/Users/alice/Library/LaunchAgents/com.example.job.plist
```

## `launchd.logs_dir`
Derives the logs directory path for an agent label.

```bash
launchd.logs_dir "com.example.job"
```

```text
/Users/alice/Library/Logs/com.example.job
```

## `launchd.write_agent_plist`
Creates a launch agent plist file, writing program arguments and optional environment pairs.

```bash
launchd.write_agent_plist \
  "/tmp/com.example.job.plist" \
  "com.example.job" \
  300 \
  "$HOME/Library/Logs/com.example.job/out.log" \
  "$HOME/Library/Logs/com.example.job/err.log" \
  --env "PATH=/usr/local/bin" \
  -- "/usr/bin/env" "bash" "-lc" "echo tick"
```

```text
/tmp/com.example.job.plist
```

## `launchd.bootstrap_agent`
Bootstraps (reloads) an agent and optionally logs progress when verbose mode is enabled.

```bash
launchd.bootstrap_agent "com.example.job" "/tmp/com.example.job.plist" "$(launchd.user_domain)" 1
```

```text
launchd: agent com.example.job loaded from /tmp/com.example.job.plist
```

## `launchd.unload_agent`
Boots out and disables an agent, logging what happened.

```bash
launchd.unload_agent "com.example.job" "/tmp/com.example.job.plist" "$(launchd.user_domain)" 1
```

```text
launchd: agent com.example.job unloaded
```
