#!/bin/sh

# 
# »È¤¤Êý
# ======
# 
# check-ping.sh <hosts file>
# 

HOSTS_FILE=$1;

if [ -z $HOSTS_FILE ]; then
	echo -e "missing hosts file"
	exit;
fi

clear
echo "Starting..."

DATA=""

output()
{
	if [ $1 = "OK" ];then
		C="\033[01;32m"
	else
		C="\033[01;31m"
	fi

	DATA="$DATA\n$C$1\033[00m	$2"
}

while true
do
	DATA=`date`

	for host in `cat $HOSTS_FILE`
	do
		ping -c 1 -w 1 $host > /dev/null 2>&1
		if [ $? -eq 0 ];then
			output OK $host
		else
			output NG $host
		fi
	done

	clear
	echo -e $DATA

	sleep 5
done
