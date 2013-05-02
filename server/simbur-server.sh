#!/bin/bash

. /etc/simbur/simbur-server.conf

USAGE="Usage: simbur-server enroll-host client-hostname | start-incremental | finish-backup | prune-backups #[dw]"

while getopts h x ; do
  case $x in
  h)  echo $USAGE
      exit 0;;
  esac
done

function enroll_host()
{
  USAGE="Usage: $0 enroll-host client-hostname"
  
  [ -z $1 ] && echo $USAGE >&2 && exit 1
  
  CLIENT_HOSTNAME=$1
  BACKUP_USER=$CLIENT_HOSTNAME
  
  # Create the backup user with its home directory on the backup device
  HOME_DIR=$BACKUP_ROOT/$BACKUP_USER
  adduser --quiet --disabled-password --gecos "" --home $HOME_DIR $BACKUP_USER
  
  # Add the user to sudoers
  echo "$BACKUP_USER ALL = NOPASSWD: BACKUP_PROGRAMS" >>/etc/sudoers.d/simbur-server.sudo
  
  # Create the key in the home directory of the new user
  # sudo to the backup user to get it in the right place
  SSH_DIR=$HOME_DIR/.ssh
  mkdir -p $SSH_DIR
  chown $BACKUP_USER:$BACKUP_USER $SSH_DIR
  chmod 700 $SSH_DIR
  
  PRIVATE_KEYFILE=$SSH_DIR/`hostname -s`_dsa
  ssh-keygen -q -t dsa -f $PRIVATE_KEYFILE -N ""
  
  CLIENT_PRIVATE_KEY=/etc/simbur/$(basename $PRIVATE_KEYFILE)
  echo "Copy the following lines to $CLIENT_PRIVATE_KEY on the CLIENT."
  cat $PRIVATE_KEYFILE
  echo "Don't copy this line."
  echo "Then type 'sudo chmod 600 $CLIENT_PRIVATE_KEY'"
  
  PUBLIC_KEYFILE=$PRIVATE_KEYFILE.pub
  AUTHORIZED_KEYS=$SSH_DIR/authorized_keys
  sudo -u $BACKUP_USER sh -c "cat $PUBLIC_KEYFILE >>$AUTHORIZED_KEYS"
  sudo -u $BACKUP_USER chmod 600 $AUTHORIZED_KEYS
}

function start_incremental()
{
  # Start an incremental backup
  # Make a hard link copy of the latest snapshot

  LATEST_SNAPSHOT=`ls $HOME | tail -n1`
  
  #echo "working directory: $PWD"
  #echo "Latest snapshot: $LATEST_SNAPSHOT"
  
  if [ -d "$LATEST_SNAPSHOT" ] ; then
    sudo cp -al $LATEST_SNAPSHOT $1
    fi
}

function finish_backup()
{
  mv $1 $2
}

function prune_backups()
{
  NO_PURGE_WINDOW=${1:-$NO_PURGE_WINDOW}
  
  #  echo No purge window: $NO_PURGE_WINDOW
  
  # TODO: Make this work for month, year
  SECONDS_PER_DAY=86400
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
    # echo $d, $DELETE_BEFORE
    if [[ -d $d && `basename $d` < $DELETE_BEFORE ]] ; then
      echo sudo rm -rf $d
      fi
    done
}

COMMAND=$1
shift

case $COMMAND in
  enroll-host)  enroll_host "$@"
    exit $?;;
    
  start-incremental)  start_incremental "$@"
    exit $?;;
    
  finish-backup)  finish_backup "$@"
    exit $?;;
    
  prune-backups)  prune_backups "$@"
    exit $?;;
    
  help) echo $USAGE
    exit 0;;
    
  *) echo $USAGE
    exit 1;;
  esac


