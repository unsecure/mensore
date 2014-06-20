#! /bin/sh
#
# linux_user.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#

# user と login shell の列挙

if [ $# -eq 0 ]; then
	TARGET_DIR=/etc/group
else
	TARGET_DIR="$@"
fi

for p in $TARGET_DIR
do
	grep -E -e '^(root|wheel|operator|admin)' $p
done

