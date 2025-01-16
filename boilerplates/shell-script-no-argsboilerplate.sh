#!/usr/bin/env bash
# {{ description }}

# Usage: $(basename "$0") [-h]
#
# Options:
#   -h    Show this help message

usage() {
    grep '^# ' "$0" | cut -c3-
    exit 0
}

while getopts "h" opt; do
    case "$opt" in
        h) usage ;;
        *) usage ;;
    esac
done

echo "Hello, world!"
