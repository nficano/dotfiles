# Prompt Module Reference

Interactive prompting helpers from `lib/bash/prompt`.

## `confirm.yesno`
Simple yes/no confirmation returning success only for affirmative replies.

```bash
if confirm.yesno "Deploy now?"; then
  echo "Confirmed"
else
  echo "Cancelled"
fi
```

```text
Deploy now? [y/N] y
Confirmed
```

## `prompt.ask_yes_no`
Handles verbose/non-interactive flows with optional default acceptance.

```bash
if prompt.ask_yes_no "Proceed with cleanup?" 1 0 1; then
  echo "Continuing"
else
  echo "Aborted"
fi
```

```text
Assuming yes: Proceed with cleanup?
Continuing
```

## `prompt.read_input`
Returns user input, honouring defaults and non-interactive fallbacks.

```bash
name=$(prompt.read_input "Name" "Unknown" 0)
echo "Hello, $name!"
```

```text
Name [Unknown]: Ada
Hello, Ada!
```

## `prompt.read_required`
Ensures a non-empty response (or emits an error).

```bash
token=$(prompt.read_required "Enter API token")
echo "Token length: ${#token}"
```

```text
Enter API token: secret123
Token length: 9
```
