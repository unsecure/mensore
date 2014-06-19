#!/usr/bin/perl -w
package sub_cron;

use strict;
use warnings;
use utf8;

sub cron{
    my $passwd = `cut -d: -f1 /etc/passwd`;
    my @user_list=split("\n",$passwd);
    my @result;
    foreach my $user(@user_list) {
        my $crontab = `crontab -u $user -l 2>/dev/null`;
        my @find=split("\n",$crontab);
        my $find = @find;
        if($find eq 0){
            next;
        }else{
			print "> $user\n";
			print $crontab;
        }
    }
}

sub analyze_cron{
    my @cons = @_;
    my @ans;
    foreach my $finder (@cons){
        if($finder=~m/^\s*,*$/){
            next;
        }
        elsif($finder=~m/^#.+$/){
            next;
        }
        push @ans,$finder;
    }
    return @ans;
}

cron();
