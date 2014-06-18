#!/usr/bin/perl -w -I./lib/

#
# »È¤¤Êı:
#   check-http.pl <URLs file>
#

use strict;
use warnings;
use LWP::UserAgent;

my $URLS_FILE = shift;
unless ($URLS_FILE) {
	die "missing URLs file";
}

my @urls = `cat $URLS_FILE`;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

foreach my $url (@urls) {

	chomp($url);

	my $response = $ua->get($url);

	if( $response->code != 200 ){
		print "HTTP NG $url (".$response->status_line.")\n";
	}

}
