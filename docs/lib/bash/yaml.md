# YAML Module Reference

`lib/bash/yaml` helpers for reading configuration values via `yq`.

## `yaml.read_list`
Reads a list from a YAML document into an array, optionally expanding environment placeholders by executing entries.

```bash
cat <<'EOF' >/tmp/config.yml
paths:
  - "echo /usr/local/bin"
  - "echo $HOME/bin"
EOF
yaml.read_list /tmp/config.yml '.paths' PATHS
printf '%s\n' "${PATHS[@]}"
```

```text
/usr/local/bin
/Users/alice/bin
```

## `yaml.read_string`
Extracts a string value, falling back to a default when blank or null.

```bash
cat <<'EOF' >/tmp/config.yml
site:
  name: "printf 'Site: example'\n"
EOF
yaml.read_string /tmp/config.yml '.site.name' "Default Site"
```

```text
Site: example
```

## `yaml.read_int`
Reads an integer value, returning the default when absent.

```bash
cat <<'EOF' >/tmp/config.yml
retries: 5
EOF
yaml.read_int /tmp/config.yml '.retries' 3
```

```text
5
```

## `yaml.glob_patterns_regex`
Transforms glob patterns into a single regular expression.

```bash
patterns=("*.log" "cache/**")
regex=$(yaml.glob_patterns_regex patterns)
echo "$regex"
```

```text
(([^/]*\.log)|([^/]*cache/.*))
```
