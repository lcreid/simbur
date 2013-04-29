#!/bin/bash

if [[ $# -ne 1 ]] ; then
  echo "usage: $0 client-hostname"
  exit 1
  fi

simbur-server enroll-host "$*"
