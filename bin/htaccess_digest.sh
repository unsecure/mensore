#! /bin/sh
#
# htaccess.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#
# Distributed under terms of the MIT license.
#

DIR=$1

USERS=ops

cat<<EOF>.htaccess
AuthType Digest
AuthName "Security Zone"
AuthDigestProvider file
AuthUserFile $DIR/.htdigest
Require valid-user
EOF

