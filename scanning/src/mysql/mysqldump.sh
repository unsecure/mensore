#!/bin/sh
#
# mysqldump.sh
#
# must 'sudo' 

if [ $# -eq 0 ]; then 
    TARGET_FILE=.
else    
    TARGET_FILE="$@"
fi

mysqldump --single-transaction --all-databases > $TARGET_FILE
