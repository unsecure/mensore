#! /bin/sh
#
# find_exec.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#
# Distributed under terms of the MIT license.
#


if [ $# -eq 0 ]; then
	TARGET_DIR=.
else
	TARGET_DIR="$@"
fi

for p in $TARGET_DIR
do
	find $p -type f -and -perm -u+x
	find $p -type f -and -perm -g+x
	find $p -type f -and -perm -o+x
done
