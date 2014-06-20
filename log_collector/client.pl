#!/usr/bin/perl -w -I../lib/

use strict;
use warnings;
use File::Tail;
use Socket;

my $remote_host = shift;
unless( $remote_host ){
	die "missing remote host";
}

my $file = shift; 
unless( $file ){
	die "missing file";
}

use Proc::Daemon;

Proc::Daemon::Init({
		work_dir        => '.',
		pid_file        => 'client.pid',
	}
);

# サーバーと接続
my $sock;
socket($sock, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
	or die "Cannot create socket: $!";

my $packed_remote_host = inet_aton($remote_host)
	or die "Cannot pack $remote_host: $!";

my $remote_port = 6666;
my $sock_addr = sockaddr_in($remote_port, $packed_remote_host)
	or die "Cannot pack $remote_host:$remote_port: $!";

connect($sock, $sock_addr)
	or die "Cannot connect $remote_host:$remote_port: $!";

my $old_handle = select $sock;
$| = 1; 
select $old_handle;

# 監視対象の設定
open(my $fh, "<", $file) or die "Cannot open $file: $!";

my @files;
while(my $line = readline $fh){ 
    chomp $line;
	my ($name, $interval) = split(/\s+/, $line);
	print "add $name interval=$interval\n";
	push(@files,File::Tail->new(name=>$name,maxinterval=>$interval));
}

close $fh;

# 監視開始
while (1) {
	my($nfound,$timeleft,@pending)=File::Tail::select(undef,undef,undef,undef,@files);
	foreach (@pending) {
#		print $sock $_->{"input"}.": ".$_->read;
		print $sock $_->read;
	}
}

# サーバーと切断
shutdown $sock, 1;
close $sock;
