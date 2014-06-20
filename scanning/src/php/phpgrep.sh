#!/bin/sh
#
# phpgrep.sh
# Copyright (C) 2014 kaoru <kaoru@bsd>
#
#

# TODO: ` hoge `, eval, decode function, sql function


if [ $# -eq 0 ]; then
	TARGET_DIR=.
else
	TARGET_DIR="$@"
fi

grep −−color=auto -n -I -r -w -E '(exec|shell_exec|suexec|passthru|proc_open|proc_close|proc_get_status|proc_nice|proc_terminate|system|popen|pclose|dl|ini_set|virtual|set_time_limit|apache_child_terminate|posix_kill|posix_mkfifo|posix_setpgid|posix_setsid|posix_setuid|escapeshellcmd|escapeshellarg)' $TARGET_DIR
