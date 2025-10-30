# Fmt Module Reference

Formatting helpers available from `lib/bash/fmt` for human-friendly output.

## `fmt.duration_us`
Converts microsecond durations into a readable string with units.

```bash
fmt.duration_us 12500
```

```text
12.5ms
```

## `fmt.bytes`
Converts a byte count into an IEC size string.

```bash
fmt.bytes 3145728
```

```text
3.00 MiB
```
