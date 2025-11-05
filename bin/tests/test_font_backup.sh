#!/usr/bin/env bash

oneTimeSetUp() {
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  FONT_BACKUP_SCRIPT="${TEST_DIR}/../font-backup"
  # shellcheck source=/dev/null
  source "$FONT_BACKUP_SCRIPT"
}

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ $item == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

assertArrayContains() {
  local needle="$1"
  shift
  if ! array_contains "$needle" "$@"; then
    fail "Expected array to contain '$needle' but contents were: $*"
  fi
}

test_default_archive_name_for_generates_expected_name() {
  local result
  result="$(default_archive_name_for "20240101-120000")"
  assertEquals "fonts-20240101-120000.tar.gz" "$result"
}

test_resolve_export_path_uses_default_when_target_missing() {
  local base="/tmp/font-backup"
  local default_name="fonts-20240101-120000.tar.gz"
  local result
  result="$(resolve_export_path "" "$base" "$default_name")"
  assertEquals "/tmp/font-backup/fonts-20240101-120000.tar.gz" "$result"
}

test_resolve_export_path_handles_relative_target() {
  local base="/var/tmp/fonts"
  local result
  result="$(resolve_export_path "backup.tar.gz" "$base")"
  assertEquals "/var/tmp/fonts/backup.tar.gz" "$result"
}

test_resolve_export_path_preserves_absolute_target() {
  local target="/Volumes/Backups/fonts.tar.gz"
  local result
  result="$(resolve_export_path "$target" "/ignored/base")"
  assertEquals "$target" "$result"
}

test_mktemp_template_for_source_matches_expected_suffixes() {
  assertEquals "font-restore.XXXXXX.tar" "$(mktemp_template_for_source "http://example.com/fonts.tar")"
  assertEquals "font-restore.XXXXXX.tgz" "$(mktemp_template_for_source "http://example.com/fonts.tgz")"
  assertEquals "font-restore.XXXXXX.tar.gz" "$(mktemp_template_for_source "http://example.com/fonts.tar.gz")"
  assertEquals "font-restore.XXXXXX.tar.gz" "$(mktemp_template_for_source "http://example.com/fonts.zip")"
}

test_collect_font_dirs_detects_existing_directories() {
  local tmp_home
  tmp_home="$(mktemp -d)"
  mkdir -p "$tmp_home/Library/Fonts"
  mkdir -p "$tmp_home/Library/Fonts Disabled"
  mkdir -p "$tmp_home/Fonts"

  local output
  local status=0
  if output="$(collect_font_dirs "$tmp_home")"; then
    status=0
  else
    status=$?
  fi

  local -a results=()
  while IFS= read -r line; do
    [[ -z $line ]] && continue
    results+=("$line")
  done <<<"$output"

  assertEquals 0 "$status"
  assertEquals 3 "${#results[@]}"
  assertArrayContains "Library/Fonts" "${results[@]}"
  assertArrayContains "Library/Fonts Disabled" "${results[@]}"
  assertArrayContains "Fonts" "${results[@]}"

  rm -rf "$tmp_home"
}

test_collect_font_dirs_returns_failure_when_missing() {
  local tmp_home
  tmp_home="$(mktemp -d)"

  local output
  local status=0
  if output="$(collect_font_dirs "$tmp_home")"; then
    status=0
  else
    status=$?
  fi

  local -a results=()
  while IFS= read -r line; do
    [[ -z $line ]] && continue
    results+=("$line")
  done <<<"$output"

  assertEquals 1 "$status"
  assertEquals 0 "${#results[@]}"

  rm -rf "$tmp_home"
}

source "$(command -v shunit2)"
