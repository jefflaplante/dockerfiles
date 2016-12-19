#! /bin/bash

VARNISH_CACHE_SIZE=${VARNISH_CACHE_SIZE:-100M}

# Start Varnish
varnishd -a :6081 -T :6082 -f /etc/varnish/default.vcl -F -s malloc,${VARNISH_CACHE_SIZE} -P /varnishd.pid &
PID1=$!

# Signal Traps
stahp() {
  kill $PID1
  rm /varnishd.pid
  echo "Killed $PID1 with TERM signal."
}

interrupt() {
  kill -SIGINT $PID1
  rm /varnishd.pid
  echo "Sent $PID1 INT signal."
}

hangup() {
  kill -SIGHUP $PID1
  /usr/share/varnish/reload-vcl -q
  echo "Sent $PID1 HUP signal."
}

# Trap Signals
trap stahp TERM
trap interrupt INT
trap hangup HUP

#Wait for child processes to finish before exiting.
wait
