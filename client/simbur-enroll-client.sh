#!/bin/bash

. /etc/simbur/simbur-client.conf

if [[ $# -ne 1 ]] ; then
  echo "usage: $0 admin-user-name-on-backup-server"
  exit 1
  fi

cat <<EOF
Note that we are about to ask you for the same password twice.
There is a good reason for asking twice, so please don't complain.
Also note that the second time, you will see the password on the
screen, so make sure that no one is looking over your shoulder.
EOF

ssh $1@$BACKUP_TARGET sudo -S /usr/bin/enroll-host `hostname -s` | tee /tmp/simbur.$$ 

sed -n '/-----BEGIN DSA PRIVATE KEY-----/,/-----END DSA PRIVATE KEY-----/p' \
  /tmp/simbur.$$ >$PRIVATE_KEYFILE
chmod 600 $PRIVATE_KEYFILE

