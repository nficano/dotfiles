#!/usr/bin/env bash
# Usage: $(basename "$0") [-h] [-f] -p param_value arg1 [arg2...]
#
# Options:
#   -h          Show help
#   -f          Example flag
#   -p VALUE    Example parameter

usage() {
    grep '^# ' "$0" | cut -c3-
    exit 1
}

flag=0
param=""

while getopts "hfp:" opt; do
    case "$opt" in
        h) usage ;;
        f) flag=1 ;;
        p) param="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

# Ensure required parameters are provided
[ -z "$param" ] && usage
[ $# -eq 0 ] && usage

# Main logic
echo "Flag: $flag"
echo "Param: $param"
echo "Arguments: $@"
