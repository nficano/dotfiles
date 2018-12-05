#!/bin/sh

# WAN HEALTHCHECK AND REPAIR FOR THE SPECTRUM UBEE DVW32CB AND ROUTER RUNNING
# TOMATO OR DD-WRT.

set -e

STATSD_HOSTNAME=${STATSD_HOSTNAME:-ip-172-16-1-164}
STATSD_PORT=${STATSD_PORT:-8125}

PUBLIC_IP=$(ip route | awk '/default/ { print $3 }')
GOOGLE_DNS_IP=8.8.8.8

MODEM_IP=${MODEM_IP:-192.168.100.1}
MODEM_USERNAME=${MODEM_USERNAME:-technician}
MODEM_PASSWORD=${MODEM_PASSWORD:-C0nf1gur3Ubee#}

MAX_RETRIES=${MAX_RETRIES:-3}
RETRY_INTERVAL=5

on_outage_detected () {
  err "lan/wan connectivity issue detected!"
  metric "failed" 1
  if is_reboot_permitted; then
    reboot_modem
    reboot_router
  else
    metric "reboot.failure.too_soon" 1
    err "router must be up for five minutes before attempting reboot"
  fi
}

on_no_issues_detected () {
  log "lan/wan connectivity appears to be ok"
  metric "succeeded" 1
}

reboot_router () {
  log "rebooting router"
  /sbin/reboot
}

reboot_modem () {
  log "rebooting modem"
  curl \
    --basic \
    --user "$MODEM_USERNAME:$MODEM_PASSWORD" \
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
    log "checking if $1 ($2) returns a 200 response (attempt $count)"
    headers="$(curl --max-time 2 --silent --dump-header - -o /dev/null $2)"

    case "$(echo $headers | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
      [23])
      log "successfully made http connection to $1 ($2)"
      metric "http_response.succeeded.2xx" 1
      return 0
      ;;

      5)
      err "$1 ($2) returned a 5xx status code. retrying in ${RETRY_INTERVAL}s"
      metric "http_response.failure.5xx" 1
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
      ;;

      *)
      err "no http connectivity to $1 ($2) retrying in ${RETRY_INTERVAL}s"
      metric "http_response.failed" 1
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
      ;;
    esac
  done
  return 1
}

is_pingable () {
  count=1
  while [ $((count)) -le $((MAX_RETRIES)) ]; do
    log "checking if $1 ($2) is pingable (attempt $count)"
    if ping -q -c 1 -W 1 $2 >/dev/null; then
      log "$1 ($2) successfully responded to ping"
      metric "ping.succeeded" 1
      return 0
    else
      err "$1 ($2) no response to ping - retrying in ${RETRY_INTERVAL}s"
      metric "ping.failed" 1
      sleep "$RETRY_INTERVAL"
      count=$((count+1));
    fi
  done
  return 1
}

is_wan_up () {
  if is_pingable 'dns' $GOOGLE_DNS_IP; then
    if is_pingable 'domain' 'google.com'; then
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

metric () {
  prefix='wan_healthcheck.connectivity'
  echo "$prefix.$1:$2|c" | nc -w 1 $STATSD_HOSTNAME $STATSD_PORT
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

run_healthcheck () {
  log "checking if lan is up"
  if is_lan_up; then
    log "checking if wan is up"
    if is_wan_up; then
      on_no_issues_detected
      exit 0
    fi
  fi
  on_outage_detected
  exit 1
}

log "starting network healthcheck"
metric "started" 1
run_healthcheck
