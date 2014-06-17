#!/usr/bin/perl -w
=put
./result/cron/cron_YYYYMMDDhhmm
        /at/at_YYYYMMDDhhmm/at_<at番号>_<user_id>_YYYYMMDDhhmm
=cut
use strict;
use warnings;
use utf8;
use Data::Dumper;

my $option=0;

require 'cron.pl';
require 'at.pl';
require 'io.pl';

&main();
exit(0);

sub main{
    foreach my $ARGV (@ARGV){	
        if($ARGV=~ m/^-/){
            if($ARGV=~ m/^-o$/){
                $option=1;
            }
            else{
                die "\n error option  : ".$ARGV."\n";
            }
        }
    }

    my @cron_result = sub_cron::cron(); 
    my @at_result = sub_at::at();
    @cron_result = sub_cron::analyze_cron(@cron_result);
    @at_result = sub_at::analyze_at(@at_result);



    if($option eq 1){
        my $date=`date +"%Y%m%d%I%M"`;
        $date =~ s/\n//;
        if (!-d "./result"){
            mkdir "./result";
            mkdir "./result/cron";
            mkdir "./result/at";
        }
        sub_io::output("result/cron/cron",0,@cron_result);
        foreach my $finder(@at_result){
            my $at_dir="result/at/at_$date/";
            if (!-d $at_dir){ 
                mkdir `mkdir $at_dir`; 
            }  
            sub_io::output("result/at/at_$date/at",@$finder[0]->[0]."_".@$finder[0]->[4],@{@$finder[1]}); 
        }
    }
}
