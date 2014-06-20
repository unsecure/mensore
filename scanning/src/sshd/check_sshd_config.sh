#! /bin/sh
#
# check_sshd_config.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#


CMD="grep --color=auto"


if [ $# -eq 0 ]; then
	TARGET=''
else
	TARGET="$@"
fi

$CMD -E \
	-e '^[[:space:]]*(PermitRootLogin|RhostsRSAAuthentication|PasswordAuthentication|PermitEmptyPasswords|ChallengeResponseAuthentication)[[:space:]]+yes' \
	-e '^[[:space:]]*(Protocol)[[:space:]]+(2[,[[:space:]]]*)?1' \
	$TARGET
