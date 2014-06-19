#!/usr/bin/perl -w -I../lib/

use IO::Select;
use IO::Socket;
use IO::Handle;

use Proc::Daemon;

my $out_dir = shift;
unless ($out_dir) {
	die "missing out dir";
}

Proc::Daemon::Init({
		work_dir        => '.',
		pid_file        => 'pid',
	}
);

my $DATA_DIR = $out_dir;

sub save_data {
	my $host = shift;
	my $data = shift;
	my $time = localtime(time);

	my $tag = shift @$data;
	chomp($tag);

	system "mkdir -p $DATA_DIR/$host/";

	open(DATA_FILE, ">> $DATA_DIR/$host/$tag") or die "can not open: $!";

	print DATA_FILE "----- [$time] -----\n";

	foreach my $line (@$data){
		print DATA_FILE $line;
	}

	close(DATA_FILE);

	print "save data => $DATA_DIR/$host/$tag\n";
}

my $listener = new IO::Socket::INET(Listen => 1, LocalPort => 7777, ReuseAddr => 1);
my $selector = new IO::Select( $listener );

while(my @ready = $selector->can_read) {
	foreach my $fh (@ready) {

		if($fh == $listener) {
			my $new = $listener->accept;
			$selector->add($new);

			my $host = $new->peerhost();
			my $port = $new->peerport();

			print "added client [$host:$port]\n";
		}
		else {
			my $host = $fh->peerhost();
			my $port = $fh->peerport();

			my @lines;
			my $input;
			while(defined($input = <$fh>)){
				push(@lines, $input);
			}

			save_data( $host, \@lines );

			$selector->remove($fh);
			$fh->close;
			print "removed client [$host:$port]\n";
		}
	}
}
