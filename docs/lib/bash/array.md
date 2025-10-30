# Array Module Reference

Public helpers from `lib/bash/array` for working with arrays in POSIX-compatible Bash.

## `array.empty`
Resets an array variable to contain no elements.

```bash
numbers=(1 2 3)
array.empty numbers
declare -p numbers
```

```text
declare -a numbers='()'
```

## `array.push`
Appends one or more values to an array variable.

```bash
colors=()
array.push colors red blue
declare -p colors
```

```text
declare -a colors='([0]="red" [1]="blue")'
```

## `array.copy`
Copies the contents of one array variable into another.

```bash
source=(alpha beta)
array.copy copy_of_source source
declare -p copy_of_source
```

```text
declare -a copy_of_source='([0]="alpha" [1]="beta")'
```

## `array.sort`
Sorts an array in-place using the system `sort`, accepting any additional sort flags.

```bash
fruits=(orange apple banana)
array.sort fruits
printf '%s\n' "${fruits[@]}"
```

```text
apple
banana
orange
```
