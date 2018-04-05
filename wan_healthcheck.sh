#!/bin/sh

#          dP
#          88
# dP    dP 88d888b. .d8888b. .d8888b.
# 88    88 88'  `88 88ooood8 88ooood8
# 88.  .88 88.  .88 88.  ... 88.  ...
# `88888P' 88Y8888' `88888P' `88888P'
#
# WAN HEALTHCHECK AND REPAIR FOR THE SPECTRUM UBEE DVW32CB AND ROUTER RUNNING
# TOMATO OR DD-WRT.
#
GATEWAY_IP=${GATEWAY_IP:-192.168.100.1}
GATEWAY_PORT=${GATEWAY_PORT:-80}

CHECK_IP=${CHECK_IP:-8.8.8.8}
CHECK_PORT=${CHECK_PORT:-53}

WAN_MAX_RETRIES=${WAN_MAX_RETRIES:-3}
UBEE_MAX_RETRIES=${UBEE_MAX_RETRIES:-3}
INTERVAL=${INTERVAL:-5}
TIMEOUT=${TIMEOUT:-1}

info() {
    fmt="$1"; shift
    # shellcheck disable=SC2059
    printf "$fmt\\n" "$@"
}

is_wan_down() {
  count=0
  ret=0
  while [ $((count)) -le $((WAN_MAX_RETRIES)) ] && [ $((ret)) -eq 0 ]; do
    if nc -w "${TIMEOUT}" "${CHECK_IP}" "${CHECK_PORT}" > /dev/null 2>&1; then
      ret=1;
      break;
    else
      sleep "$INTERVAL"
      $count++
    fi
  done
  return $ret;
}

is_modem_online() {
  count=0
  ret=0
  while [ $((count)) -le $((UBEE_MAX_RETRIES)) ] && [ $((ret)) -eq 0 ]; do
    if nc -w "${TIMEOUT}" "${GATEWAY_IP}" 80 > /dev/null 2>&1; then
      ret=1;
      break;
    else
      sleep "$INTERVAL"
      $count++
    fi
  done
  return $ret;
}

reboot_router() {
  info "Rebooting Router ..."
  /sbin/reboot
}

reboot_modem() {
  if ! is_modem_online
  then
    info "Rebooting Modem ..."
    curl \
      --basic \
      --user "technician:C0nf1gur3Ubee#" \
      -X POST \
      -d 'ResetYes=0x01' \
      -d 'FactoryDefaultConfirm=0' \
      -d 'RestoreFactoryNo=0x00' \
      -d 'UserRestoreFactoryNo=0x00' \
      -d 'RestoreWiFiNo=0x00' \
      --silent \
      http://"$GATEWAY_IP"/goform/RgFactoryDefault > /dev/null 2>&1;
      sleep 1m
    else
      info "Modem Unreachable."
      exit 1
    fi
}

detect_outage_and_repair_connection() {
  if ! is_modem_online && is_wan_down
  then
    info "WAN is not connected."
    reboot_modem
    reboot_router
  else
    info "WAN is online!"
  fi

  exit 0
}

detect_outage_and_repair_connection
