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

set -e

# PUBLIC_IP=67.250.80.1
PUBLIC_IP=$(ip route | awk '/default/ { print $3 }')
GOOGLE_DNS_IP=8.8.8.8

MODEM_IP=${MODEM_IP:-192.168.100.1}
MODEM_USERNAME=${MODEM_USERNAME:-technician}
MODEM_PASSWORD=${MODEM_PASSWORD:-C0nf1gur3Ubee#}

MAX_RETRIES=${MAX_RETRIES:-3}
RETRY_INTERVAL=5

on_outage_detected () {
  err "lan/wan connectivity issue detected!"
  if is_reboot_permitted; then
    err "rebooting modem"
    reboot_modem
    err "rebooting router"
    reboot_router
  else
    err "router must be up for five minutes before attempting reboot"
  fi
}

on_no_issues_detected () {
  log "lan/wan connectivity appears to be ok"
}

log () {
  timestamp=$(date +"%b %d %H:%M:%S")
  script=$(basename "$0")
  message="$1"; shift
  # shellcheck disable=SC2059
  printf "$timestamp ${script}[$$]: $message\\n" "$@"
  logger -p cron.debug -t $script "$message"
}

err () {
  timestamp=$(date +"%b %d %H:%M:%S")
  script=$(basename "$0")
  message="$1"; shift
  # shellcheck disable=SC2059
  printf "$timestamp ${script}[$$]: $message\\n" "$@"
  logger -p cron.err -t $script "$message"
}

reboot_router () {
  log "rebooting router"
  /sbin/reboot
}

reboot_modem () {
  log "rebooting modem"
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
    http://$MODEM_IP/goform/RgFactoryDefault > /dev/null 2>&1;
    sleep 1m
}

is_reboot_permitted () {
  seconds="$(cat /proc/uptime | awk '{printf "%0.f", $1}')"
  if [ $(($seconds/60)) -gt 5 ]; then
    return 0
  else
    return 1
  fi
}

is_http_response_ok () {
  count=1
  while [ $((count)) -le $((MAX_RETRIES)) ]; do
    log "checking if $1 ($2) is returning a 2xx or 3xx http status code (attempt $count of $MAX_RETRIES)"
    case "$(curl --max-time 2 --silent --dump-header - --output /dev/null $2 | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
      [23])
      log "successfully made http connection to $1 ($2)"
      return 0
      ;;

      5)
      err "$1 ($2) returned a 5xx status code. retrying in ${RETRY_INTERVAL}s"
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
      ;;

      *)
      err "failed to establish http connection to $1 ($2) retrying in ${RETRY_INTERVAL}s"
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
      ;;
    esac
  done
  return 1
}

is_port_open () {
  count=1
  while [ $((count)) -le $((MAX_RETRIES)) ]; do
    log "checking if $1 ($2) is listening on port $3 (attempt $count of $MAX_RETRIES)..."
    if nc -zw1 $2 $3 > /dev/null 2>&1; then
      log "$1 ($2) has port $3 open"
      return 0
    else
      err "$1 ($2) does not appear to have port $3 open retrying in ${RETRY_INTERVAL}s"
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
    fi
  done
  return 1
}

is_pingable () {
  count=1
  while [ $((count)) -le $((MAX_RETRIES)) ]; do
    log "checking if $1 ($2) is responding to ICMP requests (attempt $count of $MAX_RETRIES)"
    if ping -q -c 1 -W 1 $2 >/dev/null; then
      log "$1 ($2) successfully responded to ICMP request"
      return 0
    else
      err "$1 ($2) failed to respond to ICMP request retrying in ${RETRY_INTERVAL}s"
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
    fi
  done
  return 1
}

is_wan_up () {
  if is_pingable 'DNS' $GOOGLE_DNS_IP; then
    if is_pingable 'DNS queried domain' 'google.com'; then
      if is_http_response_ok 'domain' 'google.com'; then
        return 0
      fi
    fi
  fi
  return 1
}

is_lan_up () {
  if is_pingable 'network gateway' $PUBLIC_IP; then
    if is_http_response_ok 'modem' $MODEM_IP; then
      return 0
    fi
  fi
  return 1
}

if is_lan_up; then
  if is_wan_up; then
    on_no_issues_detected
    exit 0
  fi
fi
on_outage_detected
exit 1
