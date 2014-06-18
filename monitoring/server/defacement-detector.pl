#!/usr/bin/perl -w -I./lib/

# 
# �Ȥ���
# ======
# 
# defacement-detector.pl <url> <cmd> <args>
# 
# �����:
#   defacement-detector.pl <url> init [<count=5>]
#
# �����å�:
#   defacement-detector.pl <url> check
#
# ���ץ����
# ==========
# 
# url		�ƻ��оݤ�URL
# count		ưŪ��ʬ������������
#			ưŪ��ʬ��¿�������礭������(10���20)�ˤ���
#

my $TMP_DIR = "/tmp/defacement-detector";

my $url = shift;
my $cmd = shift;

if( index($url, "://") < 0 ){
	$url = "http://$url";
}

my $data_dir = "$TMP_DIR/$url";
$data_dir =~ s/:\/\//\//g;

sub parse_ignore_lines
{
	my ($ignore_lines) = @_;

	my %ignores;

	foreach my $ignore (@$ignore_lines){
		chomp($ignore);
		if( $ignore =~ /^(\d+),(\d+)$/ ){
			$ignores{$1} = $2 - $1 + 1;
		} else {
			$ignores{$ignore} = 1;
		}
	}

	return %ignores;
}

if( $cmd eq "check" ){

	#
	# �оݤΥڡ������ѹ����ʤ��������å�����
	#

	# ̵��Ԥ����
	my @ignore_lines = `cat $data_dir/ignores`;
	my %ignores = parse_ignore_lines(\@ignore_lines);

	# ���ߤΥڡ��������
	if( system "curl -s $url > $data_dir/new.page" ){
		die "curl error";
	}

	# ̵��Ԥ���
	my @lines = `cat $data_dir/new.page`;
	my @base_lines = `cat $data_dir/base.page`; 

	# ���
	for (my $i = 0, $num = 1; $i < $#lines; $i++, $num = $i + 1) {
		if (exists($ignores{$num})) {
#			print "ignore: $num\n";
			$i += $ignores{$num} - 1;
			next;
		}

		if( $lines[$i] ne $base_lines[$i] ){
			print "LINE $num:\n";
			print "  NEW	$lines[$i]";
			print "  OLD	$base_lines[$i]";
			exit;
		}
	}

} elsif( $cmd eq "init" ){

	#
	# �оݤΥڡ����˲��󤫥����������ơ�ưŪ��ʬ�����ꤹ��
	# ưŪ����ʬ��̵�뤹��褦�ˤ���
	#

	my $count = shift;
	$count ||= 5;

	my @lines;
	my @ignores;
	my %parsed;

	if( system "mkdir -p $data_dir" ){
		die "mkdir error";
	}

	if( system "curl -s $url > $data_dir/base.page" ){
		die "curl error";
	}

	for(my $i = 1; $i <= $count; $i++){

	print "Analyze count $i...\n";

diff:
		sleep 1;
		system "curl -s $url > $data_dir/tmp.page";
		@lines = `diff -d $data_dir/base.page $data_dir/tmp.page | grep -E "^[0-9,]+c[0-9,]+\$"`;
		
		foreach my $ignore (@lines){
			chomp($ignore);
			my ($left, $right) = split(/c/, $ignore);

			if( $left ne $right ){
				print "$left != $right\n";
				print "retry...\n";
				goto diff;
			}

			my $num = $left;
			if( $left =~ /^(\d+),(\d+)$/ ){
				$num = $1;
			}

			if( $i != 0 && not exists $parsed{$num} ){
#				print "add $left\n";
				push(@ignores, $left);
			}
		}

		%parsed = parse_ignore_lines(\@ignores);
	}


	# �񤭽Ф�
	my $file = "$data_dir/ignores"; 
	open(my $fh, ">", $file) or die "Cannot open $file: $!";

	foreach my $ignore (@ignores){
		print $fh "$ignore\n";
	}

	close $fh;

	system "rm $data_dir/tmp.page";
}
