# Initrc Module Reference

`lib/bash/initrc` loads the entire Bash stdlib bundle, ensuring downstream scripts can rely on all helper modules.

## Sourcing The Initrc
Invoking the module initializes every exported helper (`log.*`, `array.*`, `http.*`, etc.) for the current shell session.

```bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/bash/initrc"
type log.info
```

```text
log.info is a function
```
