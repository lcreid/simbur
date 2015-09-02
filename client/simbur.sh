#!/bin/bash

#DEBUG_ECHO=echo
DEBUG_ECHO=debug_echo

verbose_echo() {
  if [ "$VERBOSE" == 1 ]; then
    echo "$@"
  fi
}

debug_echo() {
  if [ "$DEBUG" == 1 ]; then
    echo "$@"
  else
    verbose_echo "$@"
  fi
}


USAGE="Usage: `basename $0` -[fhiv] [-c CONFIG_FILE] [command [arguments...]]"

usage() {
  echo $USAGE
  cat <<EOF
    -c  use CONFIG_FILE for config, instead of /etc/simbur/simbur_client.conf.
    -f  Full backup.
    -h  Print help (this message).
    -i  Incremental backup (default).
    -n  Do a dry run. Has no effect with ls command.
    -v  Verbose.

    Commands are:

    ls [file...]: List the files and directories at the backup target.
    full: Do a full backup.
    incremental: Do an incremental backup (default).
    restore [-o] [-d restore-destination] [files...]: Restore files.
      Default for files is the entire backup.
      -o: Overwrite existing files.
      -d: Restore to restore-destination. Default is to original location,
          but you must specify -o if the location already exists.
EOF
}

# Default backup type
BACKUP_TYPE=incremental

while getopts fhinvc: x ; do
  case $x in
    c)  CONFIG_FILE=$OPTARG;;
    f)  BACKUP_TYPE=full;;
    h)  usage
        exit 0;;
    i)  BACKUP_TYPE=incremental;;
    n)  DRY_RUN=--dry-run;;
    v)  VERBOSE=1;;
  esac
done
shift $((OPTIND-1))

if [[ $# -gt 0 ]]; then
  COMMAND=$1
  shift
fi

$DEBUG_ECHO COMMAND: $COMMAND

CONFIG_FILE=${CONFIG_FILE-/etc/simbur/simbur-client.conf}
. $CONFIG_FILE

$DEBUG_ECHO REMOTE_USER: $REMOTE_USER
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



simbur-ls() {
  $RSYNC_CMD --password-file=$PASSWORD rsync://$REMOTE_USER@$BACKUP_TARGET/"$1"
}

simbur-last-backup() {
  simbur-ls "$1" | sort -nk5 | tail -1
}

simbur-last-directory() {
  # One small version number changes where the file name is in the rsync output.
  simbur-last-backup "$1" | tr -s ' ' | cut -d ' ' -f5
}

password-flag() {
  if [ ! -z "$PASSWORD" ]; then
    echo -n --password-file="$PASSWORD"
  fi
}

back-up() {
  if [ ${BACKUP_SOURCE:0:1} != "/" ]; then
    echo "Backup source must be an absolute file or directory path (must start with '/')." >&2
    return 1
  fi

  START_TIME=`date +%s`

  SNAPSHOT=`date +%Y%m%d%H%M%S%Z`
  SNAPSHOT_IN_PROGRESS=$SNAPSHOT
  $DEBUG_ECHO SNAPSHOT: $SNAPSHOT
  $DEBUG_ECHO SNAPSHOT_IN_PROGRESS: $SNAPSHOT_IN_PROGRESS

  LINK_DIR=`simbur-last-directory`
  $DEBUG_ECHO LINK directory: $LINK_DIR
  if [ "$BACKUP_TYPE" != "full" ] && [ "$LINK_DIR" != . ]; then
    LINK_FLAGS="--remote-option=--link-dest=../$LINK_DIR"
    $DEBUG_ECHO Link flags: $LINK_FLAGS
    verbose_echo "$0: Starting incremental backup from $LINK_DIR."
  else
    verbose_echo "$0: Starting full backup."
  fi

  $DEBUG_ECHO Starting rsync
  # Recursively copy everything (-a) and preserve ACLs (-A) and extended attributes (-X)
  # TODO: Check --super and --fake-super and changing owner.
  $RSYNC_CMD -va \
    `password-flag` \
    $DRY_RUN \
    $LINK_FLAGS \
    $ATTRIBUTES_FLAGS \
    --numeric-ids \
    --delete \
    --delete-excluded \
    --exclude-from=$EXCLUDES \
    --log-file $LOG_DIR/$SNAPSHOT.log \
    --stats \
    $BACKUP_SOURCE \
    rsync://$REMOTE_USER@$BACKUP_TARGET/$SNAPSHOT_IN_PROGRESS >>$LOG_DIR/simbur.log 2>&1

  RETURN=$?

  if [[ $RETURN -ne 0 ]]; then
    echo simbur: Backup failed. See $LOG_DIR/simbur.log for messages.
  fi
    # --rsync-path="sudo rsync" \
    # --rsh="ssh -i $PRIVATE_KEYFILE" \

  $DEBUG_ECHO Finished rsync

  END_TIME=`date +%s`
  DURATION=$(( $END_TIME - $START_TIME ))
  HOURS=$(( $DURATION / 3600 ))
  DURATION=$(( $DURATION % 3600 ))
  MINUTES=$(( $DURATION  / 60 ))
  SECONDS=$(( $DURATION % 60 ))
  printf "simbur: Total job time: %02d:%02d:%02d\n" $HOURS $MINUTES $SECONDS

  return $RETURN
}

rsync-restore() {
  # $1 is source on backup server.
  # $2 is destination on this machine.
  # $3 if present is the backup generation to retrieve from.
  GENERATION=${3-`simbur-last-directory`}
  # TODO: Check --super and --fake-super and changing owner.
  $RSYNC_CMD -va \
    `password-flag` \
    $DRY_RUN \
    --super \
    $ATTRIBUTES_FLAGS \
    --numeric-ids \
    rsync://$REMOTE_USER@$BACKUP_TARGET/"$GENERATION"/"$1" \
    "$2"
}

restore() {
  $DEBUG_ECHO restore $# "$@"
  local OPTIND
  while getopts od: x ; do
    case $x in
      d)  RESTORE_DEST=$OPTARG;;
      o)  OVERWRITE="true";;
    esac
  done
  shift $((OPTIND-1))

  # If there's no file or directory specified to be restored
  if [[ $# -le 1 ]]; then
    RESTORE_DEST=${RESTORE_DEST-$BACKUP_SOURCE}
    if [ "$OVERWRITE" != "true" ] && [ -e "$RESTORE_DEST" ]; then
      echo "$RESTORE_DEST" exists. Use "-o" to allow overwrite. Exiting.
      return 1
    fi
    $DEBUG_ECHO Restore: all to $RESTORE_DEST
    rsync-restore "" ${RESTORE_DEST-$f}
  # there is a file or directory specified to be restored
  else
    if [ "$OVERWRITE" != "true" ]; then
      for f in "$@"; do
        if [ -e "$f" ]; then
          echo "$f" exists. Use "-o" to allow overwrite. Exiting.
          return 1
        fi
      done
    fi

    for f in "$@"; do
      $DEBUG_ECHO Restore: "$f" to ${RESTORE_DEST-$f}
      rsync-restore "$f" ${RESTORE_DEST-$f}
      # TODO: Report errors correctly from restore
    done
  fi
}



case "$COMMAND" in
  ls) $DEBUG_ECHO Doing ls
    simbur-ls "$@"
    RETURN=$?;;
  full) BACKUP_TYPE=full back-up "$@"
    RETURN=$?;;
  "") back-up "$@"
    RETURN=$?;;
  incremental) BACKUP_TYPE=incremental back-up "$@"
    RETURN=$?;;
  restore) restore "$@"
    RETURN=$?;;
  *) usage
    exit 1;;
  esac

exit ${RETURN:-0}
