#!/bin/bash

USAGE="purge-backup -h #[dwmy]"

while getopts h x
do
  case $x in
  *)  echo $USAGE
      exit 0;;
      esac
  done

simbur-server prune-backups "$@"
