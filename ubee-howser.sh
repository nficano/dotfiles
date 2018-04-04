#set -x

CHECK_IP=${CHECK_IP:-8.8.8.8}
CHECK_PORT=${CHECK_PORT:-53}
MAX_RETRIES=${MAX_RETRIES:-3}
INTERVAL=${INTERVAL:-5}
TIMEPOUT=${TIMEOUT:-1}

is_wan_up() {
  count=0
  ret=0
  while [[ $count -le $MAX_RETRIES && $ret -eq 0 ]]; do
    if nc -w1 -zw1 "$CHECK_IP" "${CHECK_PORT}" > /dev/null 2>&1; then
      ret=1;
      break;
    else
      sleep $INTERVAL
      (( count++ ))
    fi
  done
  echo "$ret"
  return $ret;
}

is_wan_up
