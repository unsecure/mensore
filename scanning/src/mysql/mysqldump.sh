#!/bin/sh
#
# mysqldump.sh
#
# must 'sudo' 

DATE=$(date +%Y%m%d)

if [ $# -eq 0 ]; then 
    TARGET_FILE=mysqldump-${DATE}
else    
    TARGET_FILE="$@"
fi

mysqldump --single-transaction --all-databases > ~/backup-mysql/${TARGET_FILE}.sql
