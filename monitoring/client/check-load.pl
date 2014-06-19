#!/usr/bin/perl -w -I./lib/

my ($limit1, $limit5, $limit15) = split(/\s+/, `cat load.txt`);

unless( `uptime` =~ /load average(?:s)?: (.+)/ ){
	die "can not get load average by uptime";
}

my ($la1, $la5, $la15) = split(/,\s*/, $1);

if( $la1 > $limit1 ){
	print "[LOAD] load average 1 min: $la1 > $limit1\n";
}

if( $la5 > $limit5 ){
	print "[LOAD] load average 5 min: $la5 > $limit5\n";
}

if( $la15 > $limit15 ){
	print "[LOAD] load average 15 min: $la15 > $limit15\n";
}
