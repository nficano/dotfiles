#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 [-f FILE_PATH] [-d DROPBOX_PATH]"
  echo "  -f FILE_PATH    : Path to the local file you want to copy (or set FILE_PATH environment variable)"
  echo "  -d DROPBOX_PATH : Path in Dropbox (local directory) where the file will be copied (or set DROPBOX_PATH environment variable)"
  echo "  -h              : Display this help message"
}

# Function to copy a file to Dropbox directory
copy_to_dropbox() {
  local file_path="${FILE_PATH}"
  local dropbox_path="${DROPBOX_PATH}"

  while getopts "f:d:h" opt; do
    case ${opt} in
      f)
        file_path=$OPTARG
        ;;
      d)
        dropbox_path=$OPTARG
        ;;
      h)
        usage
        exit 0
        ;;
      \?)
        usage
        exit 1
        ;;
    esac
  done
  shift $((OPTIND -1))

  if [[ -z "$file_path" || -z "$dropbox_path" ]]; then
    echo "Error: FILE_PATH and DROPBOX_PATH are required."
    usage
    exit 1
  fi

  if [[ ! -f "$file_path" ]]; then
    echo "Error: File '$file_path' does not exist."
    exit 1
  fi

  if [[ ! -d "$dropbox_path" ]]; then
    echo "Error: Dropbox path '$dropbox_path' does not exist."
    exit 1
  fi

  cp "$file_path" "$dropbox_path"

  if [[ $? -eq 0 ]]; then
    echo "File '$file_path' successfully copied to '$dropbox_path'."
  else
    echo "Error: File copy failed."
    exit 1
  fi
}

# Main script
copy_to_dropbox "$@"