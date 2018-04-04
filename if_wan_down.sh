#!/bin/sh
# Ubee DVW32CB

UBEE_USERNAME='technician'
UBEE_PASSWORD='C0nf1gur3Ubee#'
GATEWAY_IP=${GATEWAY_IP:-192.168.100.1}

CHECK_IP=${CHECK_IP:-8.8.8.8}
CHECK_PORT=${CHECK_PORT:-53}
MAX_RETRIES=${MAX_RETRIES:-3}
INTERVAL=${INTERVAL:-5}
TIMEOUT=${TIMEOUT:-1}

info() {
    fmt="$1"; shift
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@"
}

is_wan_down() {
  local count=0
  local ret=0
  while [[ $count -le $MAX_RETRIES && $ret -eq 0 ]]; do
    if nc -w "${TIMEOUT}" "${CHECK_IP}" "${CHECK_PORT}" > /dev/null 2>&1; then
      ret=1;
      break;
    else
      sleep "$INTERVAL"
      (( count++ ))
    fi
  done
  return $ret;
}

ubee_reboot() {
  info "Rebooting Ubee DVW32CB..."
  # TODO(nficano): check if device is reachable.
  curl \
    --basic \
    --user "$UBEE_USERNAME:$UBEE_PASSWORD" \
    -X POST \
    -d 'ResetYes=0x01' \
    -d 'FactoryDefaultConfirm=0' \
    -d 'RestoreFactoryNo=0x00' \
    -d 'UserRestoreFactoryNo=0x00' \
    -d 'RestoreWiFiNo=0x00' \
    --silent \
    http://"$GATEWAY_IP"/goform/RgFactoryDefault > /dev/null 2>&1;
}

detect_outage_and_repair_connection() {
  if is_wan_down
  then
    info "WAN is not connected."
    ubee_reboot
    # TODO(nficano): log event.
    # TODO(nficano): now reboot router just to be safe.
  fi
    info "WAN is online!"
  exit 0
}

detect_outage_and_repair_connection
