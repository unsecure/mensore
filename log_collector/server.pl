#!/usr/bin/perl -w -I../lib/

use IO::Select;
use IO::Socket;
use IO::Handle;

use Proc::Daemon;

my $out_file = shift;
unless ($out_file) {
	die "missing out file";
}

Proc::Daemon::Init({
		work_dir        => '.',
		pid_file        => 'server.pid',
	}
);

open(LOG_FILE, ">> $out_file") or die "can not open: $!";
LOG_FILE->autoflush(1);

my $listener = new IO::Socket::INET(Listen => 1, LocalPort => 6666, ReuseAddr => 1);

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

			my $input = <$fh>;
			if(defined($input)){
				my $time = localtime(time);
				printf LOG_FILE "[%s] %15s : %s", $time, $host, $input;
			}
			else{
				$selector->remove($fh);
				$fh->close;
				print "removed client [$host:$port]\n";
			}
		}
	}
}

close(LOG_FILE);
