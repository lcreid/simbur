#!/bin/bash

. ./client.conf

MACOS_FILE_TIME="stat -f %m"
LINUX_FILE_TIME="date +%s -r"

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

# Check if it's time for a backup and do it
# This is going to be platform-dependent
# See: http://stackoverflow.com/questions/11212663/filename-last-modification-date-shell-in-script

BACKUP_INTERVAL_S=`to_seconds $BACKUP_INTERVAL`

if [ -e $BACKUP_END_FILE ]; then
    # Works on Linux
    LAST_BACKUP_END_S=`date -r $BACKUP_END_FILE +%s`
  fi

touch $BACKUP_START_FILE  
  
if [[ ! -e $BACKUP_END_FILE || $(( `date +%s` - $LAST_BACKUP_END_S )) -gt $BACKUP_INTERVAL_S ]] ; then
  echo Do backup!
  sudo /usr/local/lib/simbur/incremental-backup
  fi

touch $BACKUP_END_FILE

# Sleep until the next time
# The trick is not to have the backup time skew by the duration of the backup
# and not start one immediately after another ends, if it goes too long.
# START_TIME=`date -r $BACKUP_START_FILE +%s`
# END_TIME=`date -r $BACKUP_END_FILE +%s`
# SLEEP_TIME=$(( `to_seconds $POLLING_INTERVAL` - ( $END_TIME - $START_TIME ) % $BACKUP_INTERVAL ))
# echo Sleeping $SLEEP_TIME
sleep $POLLING_INTERVAL

exit 0
