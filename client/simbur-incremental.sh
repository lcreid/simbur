#!/bin/bash

. /etc/simbur/simbur-client.conf

USAGE="Usage: `basename $0` -[fhi]"

while getopts hfi x ; do
  case $x in
  f)  BACKUP_TYPE=full;;
  h)  echo $USAGE
      exit 0;;
  i)  BACKUP_TYPE=;;
  esac
done

START_TIME=`date +%s`

SNAPSHOT=`date +%Y%m%d%H%M%S%Z`
SNAPSHOT_IN_PROGRESS=$SNAPSHOT-not-completed

# Set up the incremental
[ "$BACKUP_TYPE" = "full" ] || 
  ssh -i $PRIVATE_KEYFILE $BACKUP_USER@$BACKUP_TARGET \
    /usr/bin/simbur-server start-incremental $SNAPSHOT_IN_PROGRESS

LOG_DIR=/var/log/simbur

if [ ! -d $LOG_DIR ]; then
  if [ `mkdir -p $LOG_DIR` ]; then
    echo "`basename $0: can\'t create log directory >&2`"
    exit 1
    fi
  fi

# Some of the arguments to rsync are OS-dependent, or version dependent, or both.
case `uname` in
#  Darwin) ATTRIBUTES_FLAGS="--extended-attributes" ;;
  Darwin) ATTRIBUTES_FLAGS="--acls --xattrs" ;;
  Linux) ATTRIBUTES_FLAGS="--acls --xattrs" ;;
  *) echo "Operating system `uname` not supported."
    exit 1;;
  esac


# Recursively copy everything (-a) and preserve ACLs (-A) and extended attributes (-X)
rsync -va \
  $ATTRIBUTES_FLAGS \
  --delete \
  --delete-excluded \
  --exclude-from=$EXCLUDES \
  --rsync-path="sudo rsync" \
  --rsh="ssh -i $PRIVATE_KEYFILE" \
  --log-file $LOG_DIR/$SNAPSHOT.log \
  $BACKUP_SOURCE \
  $BACKUP_USER@$BACKUP_TARGET:$SNAPSHOT_IN_PROGRESS >>$LOG_DIR/simbur.log 2>&1

# Rename the snapshot
ssh -i $PRIVATE_KEYFILE $BACKUP_USER@$BACKUP_TARGET /usr/bin/simbur-server finish-backup $SNAPSHOT_IN_PROGRESS $SNAPSHOT

# Delete any snapshots that are no longer of interest
ssh -i $PRIVATE_KEYFILE $BACKUP_USER@$BACKUP_TARGET /usr/bin/simbur-server prune-backups 14 

END_TIME=`date +%s`
DURATION=$(( $END_TIME - $START_TIME ))
HOURS=$(( $DURATION / 3600 ))
DURATION=$(( $DURATION % 3600 ))
MINUTES=$(( $DURATION  / 60 ))
SECONDS=$(( $DURATION % 60 ))
printf "Total job time: %02d:%02d:%02d\n" $HOURS $MINUTES $SECONDS

