# Strings Module Reference

String manipulation helpers provided by `lib/bash/strings`.

## `text.substr`
Returns a substring using Bash's slicing semantics.

```bash
text.substr "abcdef" 1 3
```

```text
bcd
```

## `text.repeat`
Repeats a character or string a fixed number of times.

```bash
text.repeat "-" 5
```

```text
-----
```

## `str.trim`
Trims leading and trailing whitespace from an argument (or stdin).

```bash
str.trim $'  spaced  '
```

```text
spaced
```

## `str.lower`
Converts input to lowercase.

```bash
printf 'DEMo' | str.lower
```

```text
demo
```

## `str.upper`
Converts input to uppercase.

```bash
printf 'demo' | str.upper
```

```text
DEMO
```

## `str.urlencode`
Percent-encodes a string for URLs.

```bash
str.urlencode "name=Alice & Bob"
```

```text
name%3DAlice%20%26%20Bob
```

## `str.urldecode`
Decodes percent-encoded strings.

```bash
str.urldecode "name%3DAlice%20%26%20Bob"
```

```text
name=Alice & Bob
```

## `str.xml_escape`
Escapes XML special characters.

```bash
str.xml_escape "<tag attr=\"value\">"
```

```text
&lt;tag attr=&quot;value&quot;&gt;
```
