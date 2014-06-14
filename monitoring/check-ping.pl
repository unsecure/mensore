#!/usr/bin/perl -w -I./lib/

# 
# »È¤¤Êý
# ======
# 
# check-ping.pl <hosts file> [<sleep time=10>]
# 

use strict;
use warnings;
use Net::Ping;

$| = 1;

my $HOSTS_FILE = shift;
unless ($HOSTS_FILE) {
	die "missing hosts file";
}

my $SLEEP_TIME = shift;
unless ($SLEEP_TIME) {
	$SLEEP_TIME = 10;
}

my $ping = Net::Ping->new('icmp');

my @hosts = `cat $HOSTS_FILE`;

my $DATA = "";

sub output
{
	my ($result, $host) = @_;

	my $C;
	if($result){
		$result = "OK";
		$C="\033[01;32m";
	}else{
		$result = "NG";
		$C="\033[01;31m";
	}

	$DATA="$DATA\n$C$result\033[00m	$host";
}

system "clear";
print "Starting...";

while (1) {

	$DATA = `date`;

	foreach my $host (@hosts) {

		chomp($host);

		my $alive = $ping->ping($host, 2);

		output($alive, $host);

	}

	system "clear";
	print $DATA;

	sleep $SLEEP_TIME;
}

