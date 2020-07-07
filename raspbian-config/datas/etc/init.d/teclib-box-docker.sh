#!/bin/sh
### BEGIN INIT INFO
# Provides:          teclib-box-docker.sh
# Required-Start:    $all
# Required-Stop:
# Should-Start:      $docker
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start teclib box
### END INIT INFO

case "$1" in
  start)
    /opt/teclib-box/start.sh
    ;;
  stop)
    echo "stopped"
esac

exit 0