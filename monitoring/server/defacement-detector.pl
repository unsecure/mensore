#!/usr/bin/perl -w -I./lib/

# 
# 使い方
# ======
# 
# defacement-detector.pl <cmd> <args>
# 
# 初期化:
#   defacement-detector.pl init <url> [<count=5>]
#
# チェック:
#   defacement-detector.pl check
#
# オプション
# ==========
# 
# url		監視対象のURL
# count		動的部分を精査する回数
#			動的部分が多い場合は大きい数字(10~20)にする
#

my $TMP_DIR = "/opt/mensore/defacement-detector";
my $URLS_FILE = "$TMP_DIR/urls";

my $cmd = shift;

unless( $cmd ){
	die "missing cmd";
}

sub get_data_dir
{
	my $url = shift;

	if( index($url, "://") < 0 ){
		$url = "http://$url";
	}

	my $data_dir = "$TMP_DIR/$url";
	$data_dir =~ s/:\/\//\//g;

	return $data_dir;
}

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
	# 対象のページに変更がないかチェックする
	#

	my @urls = `cat $URLS_FILE`;

	foreach my $url (@urls){
		chomp($url);
		my $data_dir = get_data_dir($url);

		unless( -f "$data_dir/base.page" ){
			die "not initialized. \"init\" before \"check\"";
		}

		# 無視行を準備
		my @ignore_lines = `cat $data_dir/ignores`;
		my %ignores = parse_ignore_lines(\@ignore_lines);

		# 現在のページを取得
		if( system "curl -s $url > $data_dir/new.page" ){
			die "curl error";
		}

		# 無視行を削除
		my @lines = `cat $data_dir/new.page`;
		my @base_lines = `cat $data_dir/base.page`; 

		# 比較
		for (my $i = 0, $num = 1; $i < $#lines; $i++, $num = $i + 1) {
			if (exists($ignores{$num})) {
	#			print "ignore: $num\n";
				$i += $ignores{$num} - 1;
				next;
			}

			if( $lines[$i] ne $base_lines[$i] ){
				my $before = $lines[$i];
				my $after = $base_lines[$i];
				print "[DEFACEMENT] line $num $before";
				exit;
			}
		}
	}

} elsif( $cmd eq "init" ){

	#
	# 対象のページに何回かアクセスして、動的部分を特定する
	# 動的な部分は無視するようにする
	#

	my $url = shift; 
	my $data_dir = get_data_dir($url);

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


	# 書き出し
	my $file = "$data_dir/ignores"; 
	open(my $fh, ">", $file) or die "Cannot open $file: $!";

	foreach my $ignore (@ignores){
		print $fh "$ignore\n";
	}

	close $fh;

	system "echo '$url' >> $URLS_FILE";

	system "rm $data_dir/tmp.page";
}
