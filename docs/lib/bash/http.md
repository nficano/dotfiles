# HTTP Module Reference

Companion to `lib/bash/http`, detailing each helper and convenience function for building HTTP requests and inspecting responses.

## `http._error`
Writes an error message through `log.error` when available, otherwise stderr.

```bash
http._error "Unsupported protocol"
```

```text
Unsupported protocol
```

## `http._validate_var_name`
Checks whether a string is a valid Bash variable name.

```bash
if http._validate_var_name "response_var"; then
  echo "Name accepted"
fi
```

```text
Name accepted
```

## `http._ensure_curl`
Confirms `curl` is installed before making requests.

```bash
http._ensure_curl || exit 1
```

```text
# no output when curl exists; exits with an error otherwise
```

## `http._tmpfile`
Creates a temporary file, using `fs.mktmp` when available.

```bash
tmp=$(http._tmpfile http_demo)
printf 'Temp file: %s\n' "$tmp"
```

```text
Temp file: /tmp/http_demo.ab12CD
```

## `http._trim`
Trims leading and trailing whitespace from a string.

```bash
printf '>%s<\n' "$(http._trim $'  padded \n')"
```

```text
>padded<
```

## `http._urlencode`
Percent-encodes a string for safe URL usage.

```bash
encoded=$(http._urlencode "name=John Doe & Co")
echo "$encoded"
```

```text
name%3DJohn%20Doe%20%26%20Co
```

## `http._collect_params`
Splits `&`-separated query fragments into an array.

```bash
params=()
http._collect_params params "page=1&limit=20&&active=true"
printf '%s\n' "${params[@]}"
```

```text
page=1
limit=20
active=true
```

## `http._apply_params`
Applies query parameters to a base URL while preserving fragments.

```bash
final=$(http._apply_params "https://api.example.com?q=base#frag" "lang=en" "debug=1")
echo "$final"
```

```text
https://api.example.com?q=base&lang=en&debug=1#frag
```

## `http._final_header_block`
Returns the header block from the last response encountered in a header file.

```bash
block=$(http._final_header_block tests/fixtures/http_headers.txt)
printf '%s\n' "$block"
```

```text
HTTP/1.1 200 OK
Content-Type: application/json
```

## `http._header_from_block`
Extracts a header value from a header block string.

```bash
ct=$(http._header_from_block $'HTTP/1.1 200 OK\nContent-Type: text/plain\n' "Content-Type")
echo "$ct"
```

```text
text/plain
```

## `http._response_init`
Clears previously set response fields for a response prefix.

```bash
HTTP_RESPONSE_status=500
http._response_init "HTTP_RESPONSE"
echo "${HTTP_RESPONSE_status:-unset}"
```

```text
unset
```

## `http._response_set`
Stores a response field value on the provided prefix.

```bash
http._response_set "HTTP_RESPONSE" "status" "201"
echo "$HTTP_RESPONSE_status"
```

```text
201
```

## `http.response_get`
Retrieves a stored field value from a response prefix.

```bash
http._response_set "HTTP_RESPONSE" "reason" "Created"
echo "$(http.response_get HTTP_RESPONSE reason)"
```

```text
Created
```

## `http.response_header`
Looks up a header by name from the response metadata.

```bash
HTTP_RESPONSE_headers=$'HTTP/1.1 200 OK\nContent-Type: text/plain\n'
echo "$(http.response_header HTTP_RESPONSE Content-Type)"
```

```text
text/plain
```

## `http.response_headers`
Returns the full header block associated with a response.

```bash
HTTP_RESPONSE_headers=$'HTTP/1.1 204 No Content\nX-Request-Id: abc\n'
printf '%s\n' "$(http.response_headers HTTP_RESPONSE)"
```

```text
HTTP/1.1 204 No Content
X-Request-Id: abc
```

## `http.response_ok`
Checks whether the response status is in the 2xx or 3xx range.

```bash
HTTP_RESPONSE_ok=1
if http.response_ok HTTP_RESPONSE; then
  echo "Request succeeded"
fi
```

```text
Request succeeded
```

## `http.raise_for_status`
Logs an error and fails when the response status is ≥ 400.

```bash
HTTP_RESPONSE_status=404
HTTP_RESPONSE_reason="Not Found"
HTTP_RESPONSE_url="https://api.example.com/items/42"
http.raise_for_status HTTP_RESPONSE || echo "Raised"
```

```text
HTTP 404: Not Found (https://api.example.com/items/42)
Raised
```

## `http._looks_like_url`
Rudimentary check to see if an argument resembles a URL.

```bash
echo "$(http._looks_like_url "https://example.com" && echo yes)"
```

```text
yes
```

## `http._normalize_bool`
Normalizes truthy/falsey strings into `1` or `0`.

```bash
echo "$(http._normalize_bool "YeS")"
```

```text
1
```

## `http._join_lines`
Joins an array into newline-separated text.

```bash
headers=(
  "Accept: application/json"
  "User-Agent: demo"
)
printf '%s\n' "$(http._join_lines headers)"
```

```text
Accept: application/json
User-Agent: demo
```

## `http.request`
Core request helper wrapping `curl`; populates response metadata on a prefix.

```bash
http.request resp GET "https://httpbin.org/get" --params "demo=1"
printf 'Status: %s\nBody: %s\n' "$(http.response_get resp status)" "$(http.response_get resp body | head -n1)"
```

```text
Status: 200
Body: {
```

## `http._dispatch`
Shared dispatch logic used by verb-specific helpers; infers the response prefix.

```bash
http._dispatch "GET" HTTP_RESP "https://httpbin.org/status/204"
echo "$(http.response_get HTTP_RESP status)"
```

```text
204
```

## `http.get`
Convenience wrapper for `GET` requests, defaulting the response prefix.

```bash
http.get resp "https://httpbin.org/uuid"
echo "$(http.response_get resp status)"
```

```text
200
```

## `http.post`
Convenience wrapper for `POST` requests.

```bash
http.post resp "https://httpbin.org/post" --json '{"hello":"world"}'
echo "$(http.response_get resp request_body)"
```

```text
{"hello":"world"}
```

## `http.put`
Convenience wrapper for `PUT` requests.

```bash
http.put resp "https://httpbin.org/put" --bearer "token123"
printf '%s\n' "$(http.response_get resp request_headers)"
```

```text
Authorization: Bearer token123
```

## `http.delete`
Convenience wrapper for `DELETE` requests.

```bash
http.delete resp "https://httpbin.org/delete"
echo "$(http.response_get resp method)"
```

```text
DELETE
```
