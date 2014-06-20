#! /bin/sh
#
# find_elf.sh
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
	find $p -exec file {} \; | fgrep ELF
done
