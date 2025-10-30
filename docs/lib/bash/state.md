# State Module Reference

Session snapshot helpers exposed by `lib/bash/state` (public functions only).

## `state.capture_begin`
Saves the current shell environment, options, aliases, functions, PATH, and completions under the named snapshot.

```bash
state.capture_begin "pre-upgrade"
ls "$(cache.dir)/state/pre-upgrade/pre"
```

```text
aliases
completions
env
functions
path
seto
shopt
```

## `state.capture_end`
Captures a post-snapshot and writes a unified diff between the pre- and post-state when `diff` is available.

```bash
state.capture_end "pre-upgrade"
cat "$(cache.dir)/state/pre-upgrade/diff.txt"
```

```text
diff -ru /Users/alice/.cache/dotfiles/state/pre-upgrade/pre /Users/alice/.cache/dotfiles/state/pre-upgrade/post
--- ... (diff output truncated)
```
