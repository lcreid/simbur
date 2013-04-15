#!/bin/bash

. /etc/simbur/server.conf

if [[ $# -ne 2 ]] ; then
  echo "usage: $0 client-hostname"
  exit 1
  fi

CLIENT_HOSTNAME=$1
BACKUP_USER=$CLIENT_HOSTNAME

# Create the backup user with its home directory on the backup device
HOME_DIR=$BACKUP_ROOT/$BACKUP_USER
adduser --quiet --disabled-password --home $HOME_DIR $BACKUP_USER

# Add the user to sudoers
echo "$BACKUP_USER ALL = NOPASSWD: BACKUP_PROGRAMS" >>/etc/sudoers.d/simbur-server

# Create the key in the home directory of the new user
# sudo to the backup user to get it in the right place
PRIVATE_KEYFILE=`hostname`_dsa
ssh-keygen -q -t dsa -f $PRIVATE_KEYFILE
CLIENT_PRIVATE_KEY=/etc/simbur/$PRIVATE_KEYFILE
echo "Copy the following lines to $CLIENT_PRIVATE_KEY on the CLIENT."
cat $PRIVATE_KEYFILE
echo "Don't copy this line."
echo "Then type 'sudo chmod 600 $CLIENT_PRIVATE_KEY'"

PUBLIC_KEYFILE=$PRIVATE_KEYFILE.pub
SSH_DIR=$HOME_DIR/.ssh
AUTHORIZED_KEYS=$SSH_DIR/authorized_keys
mkdir -p $SSH_DIR
chown $BACKUP_USER:$BACKUP_USER $SSH_DIR
chmod 700 $SSH_DIR
sudo -u $BACKUP_USER sh -c "cat $PUBLIC_KEYFILE >>$AUTHORIZED_KEYS"
sudo -u $BACKUP_USER chmod 600 $AUTHORIZED_KEYS
