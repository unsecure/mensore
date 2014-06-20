#! /bin/sh
#
# find_doubtful_php.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#

if [ $# -eq 0 ]; then
	TARGET_DIR=.
else
	TARGET_DIR="$@"
fi

for p in $TARGET_DIR
do
	find -E $p -iregex '.*(home|admin|test|example).*\.(php|inc|htm.?)'
done
