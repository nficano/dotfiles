# SSH Agent Module Reference

Agent helpers supplied by `lib/bash/ssh_agent`.

## `ssh_agent.active_sessions`
Lists running ssh-agent PIDs owned by the current user.

```bash
ssh_agent.active_sessions
```

```text
9213
```

## `ssh_agent.start`
Starts a new ssh-agent and writes its environment variables to a file, sourcing them into the current shell.

```bash
ssh_env=/tmp/ssh-agent.env
ssh_agent.start "$ssh_env"
cat "$ssh_env"
```

```text
SSH_AUTH_SOCK=/tmp/launch-xyz/Listeners; export SSH_AUTH_SOCK;
SSH_AGENT_PID=9321; export SSH_AGENT_PID;
```

## `ssh_agent.init`
Creates or reuses an agent session, sourcing the saved environment and loading keys when necessary.

```bash
ssh_agent.init "$ssh_env"
ssh-add -l
```

```text
2048 SHA256:abcdef... id_rsa (RSA)
```
