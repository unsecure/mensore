#!/usr/bin/perl -w
package sub_at;

use strict;
use warnings;
use utf8;
use Data::Dumper;

sub at{
    my $at = `atq`;
    my @cons=split("\n",$at);
    my @result;
    foreach my $finder(@cons){
        my @atq=split(/\s+/,$finder);
        my $command = 'at -c '.$atq[0];
        my $response = `$command`;
		print "> ".$atq[0]."\n";
		print $response;
#        my @list = split("\n",$response);
#        push(@result,[\@atq,\@list]); 
    }
#    return @result;
}

at();
