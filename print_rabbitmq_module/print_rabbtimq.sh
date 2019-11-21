#!/bin/bash
### BEGIN INIT INFO
# Provides:          print_rabbitmp
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Should-Start:      $network
# Should-Stop:       $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start print_rabbitmp daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

#export LANG=fr_FR.utf8
#export LANGUAGE=fr_FR

#################################################################
# Init constants
#################################################################
DIR=/home/pi/odoo-box/picking_printer_server/print_rabbtimq_module
DAEMON_DESC="print_rabbtimq"
PIDDIR=/var/run/print_rabbtimq
PIDFILE=/var/run/$DAEMON_NAME.pid
DAEMON=$DIR/print_rabbtimq.py
LOG=/var/log/print_rabbtimq.log
DAEMON_OPTS="-l $LOG"
DAEMON_DESC="print_rabbtimq"
USER="root"
LIMIT=80
SCRIPTNAME=/etc/init.d/"$NAME"

#################################################################
# Move to directory
#################################################################
cd $DIR

#################################################################
# Create pid directory if not exist
#################################################################
if ! [ -d $PIDDIR ]
then
    mkdir $PIDDIR
fi

if ! [ -f $LOG ]
then
    touch $LOG
fi
#################################################################
# Check arguments
#################################################################
case "$1" in
    start)
        if [[ -f $PIDDIR/$PIDFILE ]]
        then
        echo $DAEMON_DESC" is already running."
    else
            echo "Starting "$DAEMON_DESC" ..."
            start-stop-daemon     --start \
                    --chdir $DIR \
                        --quiet \
                        --pidfile $PIDDIR/$PIDFILE \
                        --chuid $USER \
                        --background \
                        --make-pidfile \
                        --exec $DAEMON \
                        --oknodo \
                        -- $DAEMON_OPTS
            RETVAL=$?
        fi
    ;;

    stop)
        if [[ -f $PIDDIR/$PIDFILE ]]
        then
            echo "Stopping "$DAEMON_DESC" ..."
            start-stop-daemon     --stop \
                                --quiet \
                                --pidfile $PIDDIR/$PIDFILE \
                                --user $USER \
                                --retry TERM/5/KILL/10 \
                                --oknodo \
                                -s 9
            RETVAL=$?
            rm -f $PIDDIR/$PIDFILE
        else
            echo $DAEMON_DESC" is not running."
        fi
    ;;

    restart)
        if [[ -f $PIDDIR/$PIDFILE ]]
        then
            echo "Stopping "$DAEMON_DESC" ..."
            start-stop-daemon     --stop \
                                --quiet \
                                --pidfile $PIDDIR/$PIDFILE \
                                --user $USER \
                                --retry TERM/5/KILL/10 \
                                --oknodo \
                                -s 9
            RETVAL=$?
            rm -f $PIDDIR/$PIDFILE
            sleep 10
        else
            echo $DAEMON_DESC" is not running."
        fi
        rm -f $PIDDIR/$PIDFILE
        echo "Starting "$DAEMON_DESC" ..."
        start-stop-daemon     --start \
                            --chdir $DIR \
                            --quiet \
                            --pidfile $PIDDIR/$PIDFILE \
                            --chuid $USER \
                            --background \
                            --make-pidfile \
                            --exec $DAEMON \
                            --oknodo \
                    -- $DAEMON_OPTS
        RETVAL=$?
    ;;

  *)
    echo "Usage: $0 start|stop|restart"
    exit 1
    ;;
esac

sleep 1
exit 0

