#!/usr/bin/perl -w
package sub_at;

use strict;
use warnings;
use utf8;
use Data::Dumper;

sub at{
    my $at = `atq`;
    my @atq=split("\n",$at);
    return @atq;
}

sub analyze_at{
    my @cons = @_;
    my @result;
    foreach my $finder(@cons){
        my @atq=split(/\s+/,$finder);
        my $command = 'at -c '.$atq[0];
        my $response = `$command`;
        my @list = split("\n",$response);
        push(@result,[\@atq,\@list]); 
    }
    return @result;
}
1;
