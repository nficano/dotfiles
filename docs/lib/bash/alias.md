# Alias Module Reference

Utilities surfaced by `lib/bash/alias` for standardizing shell aliases.

## `alias.setup_ls`
Configures `ls`/`ll` aliases with colorized, directory-first listings tuned to the current platform.

```bash
alias.setup_ls
alias ls
alias ll
```

```text
alias ls='ls --color=auto -gXF'
alias ll='ls --color=auto -algX'
```
