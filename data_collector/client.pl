#!/usr/bin/perl -w -I../lib/

use strict;
use warnings;
use Socket;

my $remote_host = shift;
unless( $remote_host ){
	die "missing remote host";
}

my $tag = shift;
unless( $tag ){
	die "missing tag";
}

# サーバーと接続
my $sock;
socket($sock, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
	or die "Cannot create socket: $!";

my $packed_remote_host = inet_aton($remote_host)
	or die "Cannot pack $remote_host: $!";

my $remote_port = 7777;
my $sock_addr = sockaddr_in($remote_port, $packed_remote_host)
	or die "Cannot pack $remote_host:$remote_port: $!";

connect($sock, $sock_addr)
	or die "Cannot connect $remote_host:$remote_port: $!";

my $old_handle = select $sock;
$| = 1; 
select $old_handle;

# ヘッダ
print $sock "$tag\n";

while (defined(my $line = <STDIN>)){
	print $sock $line;
}

# サーバーと切断
shutdown $sock, 1;
close $sock;
