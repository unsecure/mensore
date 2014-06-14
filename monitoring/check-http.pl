#!/usr/bin/perl -w -I./lib/

#
# »È¤¤Êý:
#   check-http.pl <URLs file> [<sleep time=10>]
#

use strict;
use warnings;
use LWP::UserAgent;

$| = 1;

my $URLS_FILE = shift;
unless ($URLS_FILE) {
	die "missing URLs file";
}

my $SLEEP_TIME = shift;
unless ($SLEEP_TIME) {
	$SLEEP_TIME = 10;
}


my @urls = `cat $URLS_FILE`;

my $DATA = "";

sub output
{
	my ($url, $result, $status) = @_;

	my $C;
	if($result){
		$result = "OK";
		$C="\033[01;32m"
	}else{
		$result = "NG";
		$C="\033[01;31m";

		$url .= " => $C$status\033[00m";
	}

	$DATA="$DATA\n$C$result\033[00m	$url"
}

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

system "clear";
print "Starting...";

while (1) {

	$DATA = `date`;

	foreach my $url (@urls) {

		chomp($url);

		my $response = $ua->get($url);

		output($url, $response->code == 200, $response->status_line);

	}

	system "clear";
	print $DATA;

	sleep $SLEEP_TIME;
}

