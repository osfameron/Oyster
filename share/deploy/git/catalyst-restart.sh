#!/bin/sh

# Really this should suck less, its a crap version of this:
# http://use.perl.org/~zzo/journal/34146

PROJECT=foo
APP_PATH=/path/to/checkout
FCGI_SOCKET_PATH=/tmp/$PROJECT.prod.socket
PID_PATH=/var/run/$PROJECT.prod.pid

case $1 in
  start)
  echo -n "Starting PROD MT: mt_fastcgi.pl"
  cd $APP_PATH
  script/${PROJECT}_fastcgi.pl -l $FCGI_SOCKET_PATH -p $PID_PATH -d -n 5
  echo

  # make real sure it's started
  PID=`cat $PID_PATH`
  if [ -n "$PID" ]
  then
    echo "Started"
  else
    echo "Start failed - trying again"
    unlink $FCGI_SOCKET_PATH
    $0 start
  fi

  ;;

  stop)
  echo -n "Stopping PROD MT: "
  PID=`cat $PID_PATH`
  if [ -n "$PID" ]
  then
    echo -n kill $PID
    kill $PID
    echo
    unlink $FCGI_SOCKET_PATH
  else
    echo $PROJECT not running
  fi
  ;;

  restart|force-reload)
  $0 stop
  sleep 10
  $0 start
  ;;

  *)
  echo "Usage: $0 { stop | start | restart }"
  exit 1
  ;;
esac
