#!/bin/bash

. /etc/simbur/server.conf

SECONDS_PER_DAY=86400

USAGE="purge-backup -h #[dwmy]"

while getopts h x
do
  case $x in
  *)  echo $USAGE
      exit 0;;
      esac
  done

NO_PURGE_WINDOW=${1:-$NO_PURGE_WINDOW}

#  echo No purge window: $NO_PURGE_WINDOW

# TODO: Make this work for month, year
case ${NO_PURGE_WINDOW: -1} in
  [dD]) NO_PURGE_WINDOW_S=$((${NO_PURGE_WINDOW%?} * $SECONDS_PER_DAY )) ;;
  [wW]) NO_PURGE_WINDOW_S=$((${NO_PURGE_WINDOW%?} * $SECONDS_PER_DAY * 7 )) ;;
  *)   NO_PURGE_WINDOW_S=$((${NO_PURGE_WINDOW} * $SECONDS_PER_DAY )) ;;
  esac

NO_PURGE_WINDOW_S=$(( `date +%s` - $NO_PURGE_WINDOW_S ))
  
#echo No purge seconds $NO_PURGE_WINDOW_S

DELETE_BEFORE=`date +%Y%m%d000000 --date=@$NO_PURGE_WINDOW_S`

#echo $DELETE_BEFORE

for d in $BACKUP_ROOT/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*; do
  echo $d, $DELETE_BEFORE
  if [[ -d $d && `basename $d` < $DELETE_BEFORE ]] ; then
    echo sudo rm -rf $d
    fi
  done

