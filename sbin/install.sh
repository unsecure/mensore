#! /bin/sh
#
# install.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#
MODE=555
OWNER=root

CMDS_SBIN='shutdown reboot poweroff'

BACKUP_EXT=".ORG"

MSG_NG="[NG]"
MSG_UNKNOWN="[??]"

backup_cmd(){
	cmd=$1
	backupfile=$cmd$BACKUP_EXT

	if [ -e $backupfile ]; then
		echo "$MSG_UNKNOWN [$backupfile] is already exist"
		return 1
	fi

	cp $cmd $backupfile
	if [ $? -eq 0 ]; then
		# We can backup file.
		return 0
	else
		echo "$MSG_NG cannot backup [$cmd]"
		return 1
	fi

	return 1
}

install_cmd(){
	INSTALL_DIR=$1
	cmd=$2
	install -o $OWNER -m $MODE $cmd $INSTALL_DIR
	if [ $? -ne 0 ]; then
		echo "$MSG_NG can not install [$cmd]"
	fi
}

cmp_install_cmd(){
	INSTALL_DIR=$1
	cmd=$2
	cmp $cmd $INSTALL_DIR/$cmd
	if [ 0 -eq $? ]; then
		echo "$cmd is same"
		return
	fi
	backup_cmd "$INSTALL_DIR/$cmd" && install_cmd "$INSTALL_DIR" "$cmd"
}

cmp_install_cmds(){
	INSTALL_DIR=$1
	CMDS=$2
	for cmd in $CMDS
	do
		echo $cmd
		cmp_install_cmd $INSTALL_DIR $cmd
	done
}
cmp_install_cmds /sbin "$CMDS_SBIN"
