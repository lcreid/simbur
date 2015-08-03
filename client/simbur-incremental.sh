#!/bin/bash

DEBUG_ECHO=echo
#DEBUG_ECHO=/bin/true

USAGE="Usage: `basename $0` -[fhi] -c CONFIG_FILE [ls]"

while getopts hfic: x ; do
  case $x in
    c)  CONFIG_FILE=$OPTARG;;
    f)  BACKUP_TYPE=full;;
    h)  echo $USAGE
        exit 0;;
    i)  BACKUP_TYPE=;;
  esac
done
shift $((OPTIND-1))

if [[ $# -gt 1 ]]; then
  echo $USAGE >&2
  exit 1
elif [[ $# -eq 1 ]]; then
  COMMAND=$1
  shift
fi

$DEBUG_ECHO COMMAND: $COMMAND

CONFIG_FILE=${CONFIG_FILE-/etc/simbur/simbur-client.conf}
. $CONFIG_FILE

$DEBUG_ECHO BACKUP_TARGET: $BACKUP_TARGET
$DEBUG_ECHO BACKUP_USER: $BACKUP_USER
$DEBUG_ECHO BACKUP_SOURCE: $BACKUP_SOURCE
$DEBUG_ECHO EXCLUDES: $EXCLUDES
$DEBUG_ECHO PRIVATE_KEYFILE: $PRIVATE_KEYFILE
$DEBUG_ECHO BACKUP_START_FILE: $BACKUP_START_FILE
$DEBUG_ECHO BACKUP_END_FILE: $BACKUP_END_FILE
$DEBUG_ECHO BACKUP_INTERVAL: $BACKUP_INTERVAL
$DEBUG_ECHO POLLING_INTERVAL: $POLLING_INTERVAL

LOG_DIR=${LOG_DIR-/var/log/simbur}
$DEBUG_ECHO LOG_DIR: $LOG_DIR

if [ ! -d $LOG_DIR ]; then
  if [ `mkdir -p $LOG_DIR` ]; then
    echo "`basename $0`: can\'t create log directory" >&2
    exit 1
  fi
fi

START_TIME=`date +%s`

SNAPSHOT=`date +%Y%m%d%H%M%S%Z`
SNAPSHOT_IN_PROGRESS=$SNAPSHOT-not-completed
$DEBUG_ECHO SNAPSHOT: $SNAPSHOT
$DEBUG_ECHO SNAPSHOT_IN_PROGRESS: $SNAPSHOT_IN_PROGRESS

# Some of the arguments to rsync are OS-dependent, or version dependent, or both.
case `uname` in
#  Darwin) ATTRIBUTES_FLAGS="--extended-attributes" ;;
#  Darwin) ATTRIBUTES_FLAGS="-E" ;;
# Backup Bouncer does this in test: flags="-avNHAX --protect-args --fileflags --force-change --rsync-path=$rsync"
# See: https://github.com/n8gray/Backup-Bouncer/blob/master/copiers.d/15-rsync-macports.cp
  Darwin) RSYNC_CMD="/opt/local/bin/rsync"
    ATTRIBUTES_FLAGS="-NHAX --fileflags --force-change" ;;
  Linux) RSYNC_CMD="rsync"
    ATTRIBUTES_FLAGS="$ACLS --xattrs" ;;
  *) echo "`basename $0`: Operating system `uname` not supported." >&2
    exit 1;;
esac

$DEBUG_ECHO RSYNC_CMD: $RSYNC_CMD
$DEBUG_ECHO ATTRIBUTES_FLAGS: $ATTRIBUTES_FLAGS

case "$COMMAND" in
  ls) echo Doing ls
    $RSYNC_CMD rsync://admin@$BACKUP_TARGET
    exit $?;;
  "") $DEBUG_ECHO No command;;
  *) echo $USAGE >&2
    exit 1;;
  esac

# Set up the incremental
# [ "$BACKUP_TYPE" = "full" ] ||
#   ssh -i $PRIVATE_KEYFILE $BACKUP_USER@$BACKUP_TARGET \
#     /usr/bin/simbur-server start-incremental $SNAPSHOT_IN_PROGRESS

$DEBUG_ECHO Starting rsync
# Recursively copy everything (-a) and preserve ACLs (-A) and extended attributes (-X)
$RSYNC_CMD -va \
  $ATTRIBUTES_FLAGS \
  --numeric-ids \
  --delete \
  --delete-excluded \
  --exclude-from=$EXCLUDES \
  --log-file $LOG_DIR/$SNAPSHOT.log \
  $BACKUP_SOURCE \
  rsync://admin@$BACKUP_TARGET/$SNAPSHOT_IN_PROGRESS >>$LOG_DIR/simbur.log 2>&1

  # --rsync-path="sudo rsync" \
  # --rsh="ssh -i $PRIVATE_KEYFILE" \

$DEBUG_ECHO Finished rsync

exit 1 # bail with error for now.

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
