# AI Module Reference

Utilities for `lib/bash/ai`, covering agent management helpers and OpenAI integration wrappers.

## `ai._debug_emit`
Logs a debug message through `log.debug` when available, falling back to stderr.

```bash
ai._debug_emit "Loaded ${#ai__agent_names[@]} AI agents"
```

## `ai._debug_dump_response`
Prints a preview of an OpenAI response body when parsing fails and `AI_OPENAI_DEBUG` is set.

```bash
ai._debug_dump_response "jq parse failed" "$raw_response_body"
```

## `ai._strip_quotes`
Removes matching leading and trailing quotes from a value.

```bash
clean_value=$(ai._strip_quotes "\"hello\"")
```

## `ai._join_lines`
Joins the contents of an array variable into a newline-delimited string, trimming trailing empties.

```bash
instruction_lines=( "Step one" "Step two" "" )
ai._join_lines instruction_lines joined
printf '%s\n' "$joined"
```

## `ai._agent_index`
Returns the index of an agent name in the loaded agent arrays.

```bash
idx=$(ai._agent_index "writer") && printf 'Writer index: %s\n' "$idx"
```

## `ai._file_mtime`
Reports the modification time (epoch seconds) for a given file.

```bash
mtime=$(ai._file_mtime "$HOME/.agents") || echo "Missing agent file"
```

## `ai._resolve_agents_file`
Determines the path to the agents configuration file, respecting `AI_AGENTS_FILE`, `DOTFILES_ROOT`, and repository root defaults.

```bash
agents_file=$(ai._resolve_agents_file)
```

## `ai._load_agents`
Loads agent definitions from the resolved agents file into internal arrays.

```bash
ai._load_agents "$HOME/.agents"
```

## `ai._ensure_agents_loaded`
Reloads agents if the source file changed or has not been initialized yet.

```bash
if ai._ensure_agents_loaded; then
  ai.agent_names
fi
```

## `ai.agent_names`
Prints all available agent names, one per line.

```bash
ai.agent_names | sort
```

## `ai.agent_exists`
Succeeds when the given agent has been defined; returns failure otherwise.

```bash
if ai.agent_exists "reviewer"; then
  echo "Reviewer agent is ready"
fi
```

## `ai.agent_require`
Enforces the presence of an agent, logging an error if it is missing.

```bash
ai.agent_require "editor" || exit 1
```

## `ai.agent_role`
Outputs the stored role description for an agent.

```bash
role=$(ai.agent_role "writer")
printf 'Writer role: %s\n' "$role"
```

## `ai.agent_instruction`
Returns the instruction block associated with an agent.

```bash
instruction=$(ai.agent_instruction "editor")
printf '%s\n' "$instruction"
```

## `ai.agent_rules`
Loads the agent's rules into an output array variable.

```bash
rules_var=()
ai.agent_rules "reviewer" rules_var
printf '* %s\n' "${rules_var[@]}"
```

## `ai.agent_prompt`
Renders the full system prompt for an agent, including role, instruction, and rules.

```bash
prompt=$(ai.agent_prompt "helper")
printf '%s\n' "$prompt"
```

## `ai._openai_init`
Initializes cached OpenAI credentials by reading environment variables.

```bash
ai._openai_init
```

## `ai.openai_api_key`
Prints the cached OpenAI API key after initialization.

```bash
api_key=$(ai.openai_api_key)
```

## `ai.openai_api_base`
Returns the API base URL, defaulting to `https://api.openai.com`.

```bash
api_base=$(ai.openai_api_base)
```

## `ai.openai_require_api_key`
Checks that an OpenAI API key is available, logging an error if missing.

```bash
ai.openai_require_api_key || exit 1
```

## `ai.openai_request`
Issues an HTTP request against the OpenAI API via `http.request`, storing the response in a reference variable.

```bash
ai.openai_request response_ref "POST" "/v1/models" "" "application/json"
status=$(http.response_get "$response_ref" status)
```

## `ai.openai_chat_completion`
Convenience wrapper for posting to `/v1/chat/completions`.

```bash
payload='{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Ping?"}]}'
ai.openai_chat_completion response_ref "$payload"
```

## `ai.openai_chat_payload`
Builds a chat completion payload with system and user prompts.

```bash
chat_payload=$(ai.openai_chat_payload "gpt-4o-mini" "You are concise." "Explain Bash arrays." 0.2)
printf '%s\n' "$chat_payload"
```

## `ai.openai_agent_chat_payload`
Uses an agent's prompt to build a chat completion payload.

```bash
chat_payload=$(ai.openai_agent_chat_payload "gpt-4o-mini" "writer" "Draft a release note.")
```

## `ai.openai_log_error`
Logs meaningful error information extracted from an HTTP response reference.

```bash
ai.openai_log_error "$response_ref" "OpenAI call failed"
```

## `ai.openai_message_text`
Extracts plain text content from an OpenAI API response body using `jq`.

```bash
message=$(ai.openai_message_text "$response_ref") || echo "No content available"
```
