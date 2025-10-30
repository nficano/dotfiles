# Shell Module Reference

Utility functions from `lib/bash/shell` for lazy loading and shell customisation.

## `shell.defer`
Lazily defines a command so it runs an initializer the first time it is invoked.

```bash
shell.defer mytool 'mytool(){ echo "mytool invoked: $*"; }'
mytool build
```

```text
mytool invoked: build
```

## `shell.setopt`
Enables a `shopt` option when available.

```bash
shell.setopt nocaseglob
shopt nocaseglob
```

```text
nocaseglob        on
```

## `shell.import`
Sources a file (or defers sourcing behind a tool placeholder).

```bash
cat <<'EOF' >/tmp/demo-lib.sh
demo_fn(){ echo "demo lib loaded"; }
EOF
shell.import /tmp/demo-lib.sh
demo_fn
```

```text
demo lib loaded
```

## `shell.eval`
Evaluates the output of a command, optionally wrapping it with `shell.defer`.

```bash
cat <<'EOF' >/tmp/env.sh
echo 'export DEMO_VAR=hello'
EOF
chmod +x /tmp/env.sh
shell.eval "/tmp/env.sh"
echo "$DEMO_VAR"
```

```text
hello
```

## `shell.setup_prompt`
Installs a custom PS1 prompt with the iTerm2-style path helper.

```bash
shell.setup_prompt
echo "$PS1"
```

```text
\h \[\e[1;32m\]\$(shell.iterm2_style_path)\[\e[0m\] [\A] >
```

## `shell.iterm2_style_path`
Builds a collapsed path string (e.g., `p/r/project`) for prompt display.

```bash
dirs +0
shell.iterm2_style_path
```

```text
p/r/project
```
