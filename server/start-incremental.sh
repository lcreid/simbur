#!/bin/bash

# Start an incremental backup
# Make a hard link copy of the latest snapshot

#echo "Command line: $0 $*"

. /etc/simbur/server.conf

LATEST_SNAPSHOT=`ls $HOME | tail -n1`

#echo "working directory: $PWD"
#echo "Latest snapshot: $LATEST_SNAPSHOT"

if [ -d "$LATEST_SNAPSHOT" ] ; then
  sudo cp -al $LATEST_SNAPSHOT $1
  fi

