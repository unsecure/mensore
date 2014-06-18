#!/usr/bin/perl -w -I./lib/

# 
# »È¤¤Êý
# ======
# 
# check-ping.pl <hosts file>
# 

use strict;
use warnings;
use Net::Ping;

my $HOSTS_FILE = shift;
unless ($HOSTS_FILE) {
	die "missing hosts file";
}

my $ping = Net::Ping->new('icmp');

my @hosts = `cat $HOSTS_FILE`;

foreach my $host (@hosts) {

	chomp($host);

	my $alive = $ping->ping($host, 1);

	unless( $alive ){
		print "PING NG $host\n";
	}

}
