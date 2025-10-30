# AWS Module Reference

Surface functions from `lib/bash/aws` for interpreting AWS CLI output.

## `aws.s3_lines_are_socket_warnings`
Identifies whether a set of S3 sync output lines only contains benign socket warnings (and routine log chatter).

```bash
logs=(
  "2024-01-01 12:00:00,000 - WARNING - warning: skipping file s3://bucket/object due to socket error"
  "2024-01-01 12:00:00,050 - INFO - sync complete"
)
if aws.s3_lines_are_socket_warnings "${logs[@]}"; then
  echo "Treat as benign socket warning"
else
  echo "Investigate output"
fi
```

```text
Treat as benign socket warning
```
