# Lock Module Reference

File-lock primitives from `lib/bash/lock` for coordinating concurrent scripts.

## `lock.acquire`
Creates (or reuses) a lock file and returns a descriptor spec when the lock is obtained.

```bash
lock_spec=$(lock.acquire "nightly-job" 1) || exit 1
echo "$lock_spec"
```

```text
42:/tmp/nightly-job.lock
```

## `lock.release`
Releases the file lock referenced by the descriptor spec and removes the lock file.

```bash
lock.release "$lock_spec"
test ! -e "/tmp/nightly-job.lock" && echo "Lock cleared"
```

```text
Lock cleared
```
