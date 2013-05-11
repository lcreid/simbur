#!/bin/bash

# Checking the file mod time is platform-dependent
# See: http://stackoverflow.com/questions/11212663/filename-last-modification-date-shell-in-script
case `uname` in
  Darwin) FILE_MOD_TIME="stat -f %m" ;;
  Linux) FILE_MOD_TIME="date +%s -r" ;;
  *) echo "Operating system `uname` not supported."
    exit 1;;
  esac

syslog="logger -t simburd"

function to_seconds()
{
  SECONDS_PER_DAY=86400
    
#  echo to_seconds called with $1 >&2
  
  case ${1: -1} in
    [dD]) SECONDS=$(( ${1%?} * $SECONDS_PER_DAY )) ;;
    [wW]) SECONDS=$(( ${1%?} * $SECONDS_PER_DAY * 7 )) ;;
    [hH]) SECONDS=$(( ${1%?} * 60 * 60 )) ;;
    [M]) SECONDS=$(( ${1%?} * 60 )) ;;
    [sS]) SECONDS=$1 ;;
    *)  SECONDS=$(( ${1} * $SECONDS_PER_DAY )) ;;
    esac
  
#  echo to_seconds returning $SECONDS >&2
    
  echo $SECONDS
}
  
while true; do
  # Reread the configuration and recalculate everything each time through,
  # so there's less need to kill and restart the daemon.
  . /etc/simbur/simbur-client.conf
  
  BACKUP_INTERVAL_S=`to_seconds $BACKUP_INTERVAL`

  # Check if it's time for a backup and do it
  
  if [ -e $BACKUP_END_FILE ]; then
      LAST_BACKUP_END_S=`$FILE_MOD_TIME $BACKUP_END_FILE`
    fi
    
  if [[ ! -e $BACKUP_END_FILE || $(( `date +%s` - $LAST_BACKUP_END_S )) -gt $BACKUP_INTERVAL_S ]] ; then
    $syslog "Backup started"
    touch $BACKUP_START_FILE  
    ( /usr/bin/simbur-incremental 2>&1 ) | $syslog
    touch $BACKUP_END_FILE
    $syslog "Backup ended"
    fi
  
  # Sleep until the next time
  # The trick is not to have the backup time skew by the duration of the backup
  # and not start one immediately after another ends, if it goes too long.
  # START_TIME=`date -r $BACKUP_START_FILE +%s`
  # END_TIME=`date -r $BACKUP_END_FILE +%s`
  # SLEEP_TIME=$(( `to_seconds $POLLING_INTERVAL` - ( $END_TIME - $START_TIME ) % $BACKUP_INTERVAL ))
  # echo Sleeping $SLEEP_TIME
  sleep $POLLING_INTERVAL
done

exit 0
