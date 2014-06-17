#!/usr/bin/perl -w
package sub_io;

use strict;
use warnings;
use utf8;

sub input{
    my @input_result;
    open (FILE, $_[0]) or die "$!";
    while (<FILE>) {
        push @input_result, $_;
    }
    close (FILE);
    return @input_result;
}

sub output{
    my $out;
    my ($file,$count,@data)=@_;
    my $filename=$file."_".$count."_".`date +"%Y%m%d%I%M"`;
    open (FILE, ">>$filename") or die "file open error";
        foreach $out (@data) {
            print FILE $out."\n";
    }
    close (FILE);
    return $filename;
}
1;
