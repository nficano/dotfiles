# Cache Module Reference

High-level cache helpers defined in `lib/bash/cache` for simple file-backed memoization.

## `cache.dir`
Ensures and returns the base cache directory used by the helpers.

```bash
cache_dir=$(cache.dir)
printf 'Cache directory: %s\n' "$cache_dir"
```

```text
Cache directory: /Users/alice/.cache/dotfiles
```

## `cache.path_for`
Generates the on-disk path that would be used for a given cache key.

```bash
printf '%s\n' "$(cache.path_for "weather/forecast")"
```

```text
/Users/alice/.cache/dotfiles/weather__forecast
```

## `cache.get`
Reads cached content for a key when present (and optionally fresh within a TTL).

```bash
printf 'latest-data' | cache.set "status/latest"
printf '%s\n' "$(cache.get "status/latest")"
```

```text
latest-data
```

## `cache.set`
Writes stdin to the cache entry for the given key, creating directories as needed.

```bash
printf 'payload=42' | cache.set "demo/payload"
test -f "$(cache.path_for "demo/payload")" && echo "Cache stored"
```

```text
Cache stored
```

## `shell.eval_cached`
Caches the result of a command that emits shell assignments, evaluating them into the current shell after retrieval.

```bash
shell.eval_cached "demo-key" 60 "echo 'greeting=\"hi\"'"
printf '%s\n' "$greeting"
```

```text
hi
```
