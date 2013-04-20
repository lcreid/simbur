#!/bin/bash

cat <<EOF
Note that we are about to ask you for the same password twice.
There is a good reason for asking twice, so please don't complain.
Also note that the second time, you will see the password on the
screen, so make sure that no one is looking over your shoulder.
EOF

ssh $1@$BACKUP_TARGET sudo enroll-host `hostname` | tee /tmp/simbur.$$ 

sed -n '/-----BEGIN DSA PRIVATE KEY-----/,/-----END DSA PRIVATE KEY-----/p' \
  /tmp/simbur.$$ >$PRIVATE_KEYFILE

