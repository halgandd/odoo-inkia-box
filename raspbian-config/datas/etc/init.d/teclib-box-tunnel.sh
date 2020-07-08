#!/bin/sh
### BEGIN INIT INFO
# Provides:          teclib-box-tunnel.sh
# Required-Start:    $all
# Required-Stop:
# Should-Start:      $docker
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start teclib box
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin

case "$1" in
  start)
    . /root/.teclib-box.env
    if ! [ -z "$ODOO_HOST" ]; then
      if ! [ -z "$ODOO_SSH_PORT_TUNNEL" ]; then
        IP=$(host $ODOO_HOST | awk '{ print $4 }')
        ssh-keyscan -H $IP >> ~/.ssh/known_hosts
        ssh -NR $ODOO_SSH_PORT_TUNNEL:localhost:22 debian@$IP &
      fi
    fi
    ;;
  stop)
    echo "Stop tunnel"
esac

exit 0