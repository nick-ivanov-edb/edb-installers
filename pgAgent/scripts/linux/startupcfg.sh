#!/bin/sh

# Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <PGPORT> <PGUSER> <SYSTEMUSER> <Install dir> "
    exit 127
fi

PG_PORT=$1
PG_USER=$2
SYSTEM_USER=$3
INSTALL_DIR=$4

# Exit code
WARN=0

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

USER_HOME_DIR=`cat /etc/passwd | grep $SYSTEM_USER | cut -d":" -f6`
touch $INSTALL_DIR/service.log
chown $SYSTEM_USER:$SYSTEM_USER $INSTALL_DIR/service.log
cat $INSTALL_DIR/installer/pgAgent/pgpass >> $USER_HOME_DIR/.pgpass
chmod 0600 $USER_HOME_DIR/.pgpass
chown $SYSTEM_USER:$SYSTEM_USER $USER_HOME_DIR/.pgpass

# Write the startup script
cat <<EOT > "/etc/init.d/pgagent"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: pgAgent Service script for Linux

start()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgagent -l2 -s $INSTALL_DIR/service.log host=localhost port=$PG_PORT dbname=postgres user=$PG_USER' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "exec $INSTALL_DIR/bin/pgagent -l2 -s $INSTALL_DIR/service.log host=localhost port=$PG_PORT dbname=postgres user=$PG_USER " &
       exit 0
    else
       echo "pgAgent already running"
       exit 1
    fi
}

stop()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgagent -l2 -s $INSTALL_DIR/service.log host=localhost port=$PG_PORT dbname=postgres user=$PG_USER' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgAgent not running"
        exit 2
    else
        kill -9 \$PID
    fi
}
status()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgagent -l2 -s $INSTALL_DIR/service.log host=localhost port=$PG_PORT dbname=postgres user=$PG_USER' | grep -v grep | awk '{print \$2}'\`

    if [ "x$PID" = "x" ];
    then
        echo "pgAgent not running"
    else
        echo "pgAgent is running (PID: $PID)"
    fi
    exit 0
}

# See how we were called.
case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 3
        start
        ;;
  *)
        echo \$"Usage: \$0 {start|stop|restart}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/pgagent" || _warn "Failed to set the permissions on the startup script (/etc/init.d/pgagent/)"

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $CHKCONFIG ];
then
    /sbin/chkconfig --add pgagent
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $UPDATECONFIG ];
then
    /usr/sbin/update-rc.d pgagent defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi


#SERVICE=`which service`
#echo "Starting pgagent"
#if [ ! "x$SERVICE" = "x" ]; then
#    $SERVICE pgagent start
#    if [ $? -ne 0 ]; then
#        _warn "Failed to start pgagent"
#    fi
#elif [ -f /sbin/service ]; then
#    /sbin/service pgagent start    
#else
#    /etc/init.d/pgagent start
#fi

echo "$0 ran to completion"
exit $WARN
