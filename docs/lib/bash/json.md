# JSON Module Reference

Utilities made available by `lib/bash/json` for basic JSON-safe encoding.

## `json.escape`
Escapes backslashes, quotes, and control characters for embedding in JSON strings.

```bash
json.escape $'Line 1\nLine "2"'
```

```text
Line 1\nLine \"2\"
```
