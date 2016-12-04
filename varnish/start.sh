#! /bin/bash

VARNISH_CACHE_SIZE=${VARNISH_CACHE_SIZE:-100M}

# Start Varnish
varnishd -a :6081 -T :6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -F -s malloc,${VARNISH_CACHE_SIZE} -P /varnishd.pid &
PID1=$!

# Start Varnish NCSA Logger
varnishncsa &
PID2=$!

# Signal Traps
stahp() {
  kill $PID1
  kill $PID2
  rm /varnishd.pid
  echo "Killed $PID1 and $PID2 with TERM signal."
}

interrupt() {
  kill -SIGINT $PID1
  kill -SIGINT $PID2
  rm /varnishd.pid
  echo "Sent $PID1 and $PID2 INT signal."
}

hangup() {
  kill -SIGHUP $PID1
  kill -SIGHUP $PID2
  /usr/share/varnish/reload-vcl -q
  echo "Sent $PID1 and $PID2 HUP signal."
}

# Trap Signals
trap stahp TERM
trap interrupt INT
trap hangup HUP

#Wait for child processes to finish before exiting.
wait

