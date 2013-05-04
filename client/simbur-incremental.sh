#!/bin/bash

. /etc/simbur/simbur-client.conf

START_TIME=`date +%s`

SNAPSHOT=`date +%Y%m%d%H%M%S%Z`
SNAPSHOT_IN_PROGRESS=$SNAPSHOT-not-completed

# Set up the incremental
ssh -i $PRIVATE_KEYFILE $BACKUP_USER@$BACKUP_TARGET /usr/bin/simbur-server start-incremental $SNAPSHOT_IN_PROGRESS

# Recursively copy everything (-a) and preserve ACLs (-A) and extended attributes (-X)
rsync -vaAX \
  --delete \
  --delete-excluded \
  --exclude-from=$EXCLUDES \
  --rsync-path="sudo rsync" \
  --rsh="ssh -i $PRIVATE_KEYFILE" \
  --log-file $SNAPSHOT.log \
  $BACKUP_SOURCE \
  $BACKUP_USER@$BACKUP_TARGET:$SNAPSHOT_IN_PROGRESS >>/var/log/simbur.log

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

