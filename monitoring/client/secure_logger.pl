#!/usr/bin/perl -w -I../../lib/

use strict;
use warnings;
use File::Tail;
use IO::Handle;

use Proc::Daemon;

Proc::Daemon::Init({
		work_dir        => '.',
		pid_file        => 'secure_logger.pid',
	}
);

my $file = File::Tail->new(
    name=>"/var/log/secure",
    interval=>1,
    maxinterval=>1
);
my $line;

open(FH, ">> log_secure.log") or die "can not open: $!";
FH->autoflush(1);

while (defined($line=$file->read)) {

    if ($line =~ /sshd/) {
        if (&judgeSSH($line)) {
            print FH "$line";
        }
    }

    if ($line =~ /sudo/) {
        if (&judgeSUDO($line)) {
            print FH "$line";
        }
    }
}

close(FH);

sub judgeSSH {
    my $line = shift;

    if ($line =~ /Accepted publickey/i) {
        return 1;
    }
    if ($line =~ /Failed publickey/i) {
        return 1;
    }
    if ($line =~ /Invalid user/i) {
        return 1;
    }
    if ($line =~ /Failed password/i) {
        return 1;
    }

    return 0;
}

sub judgeSUDO {
    my $line = shift;

    if ($line =~ /authentication failure/i) {
        return 1;
    }
    if ($line =~ /incorrect password/i) {
        return 1;
    }
    if ($line =~ /user NOT in sudoers/i) {
        return 1;
    }
    if ($line =~ /pam_unix\(su:session\)/i) {
        return 1;
    }

    return 0;
}

__END__

############### 
# 検証
############### 
# 
# 検証環境
# CentOS 6.5 64bit
# OpenSSH_5.3p1, OpenSSL 1.0.1e-fips 11 Feb 2013
# LogLevel VERBOSE
# PasswordAuthentication no
#
# ############## 
# # ssh 
# ############## 
# 
# 公開鍵認証で成功
# Jun 15 11:38:01 vagrant-centos65 sshd[10902]: Failed publickey for vagrant from 192.168.33.1 port 62787 ssh2
# Jun 15 11:38:01 vagrant-centos65 sshd[10902]: Found matching RSA key: dd:3b:b8:2e:85:04:06:e9:ab:ff:a8:0a:c0:04:6e:d6
# Jun 15 11:38:01 vagrant-centos65 sshd[10902]: Accepted publickey for vagrant from 192.168.33.1 port 62787 ssh2
# 
# 公開鍵認証で失敗
# Jun 15 11:42:36 vagrant-centos65 sshd[10924]: Failed publickey for vagrant from 192.168.33.1 port 62791 ssh2
# 
#
# 存在しないユーザ
# Jun 15 11:40:38 vagrant-centos65 sshd[10922]: Invalid user hoge from 192.168.33.1
# Jun 15 11:40:38 vagrant-centos65 sshd[10923]: input_userauth_request: invalid user hoge
# 
# パスワード失敗
# Jun 15 11:48:07 vagrant-centos65 sshd[10946]: Failed password for vagrant from 192.168.33.1 port 62794 ssh2
# 
# パスワード失敗（存在しないユーザ）
# Jun 15 11:40:41 vagrant-centos65 sshd[10922]: Failed password for invalid user hoge from 192.168.33.1 port 62790 ssh2
# 
# パスワード認証不可でパスワード認証を試行
# Jun 15 11:53:48 vagrant-centos65 sshd[11000]: Failed publickey for vagrant from 192.168.33.1 port 62797 ssh2
# 
# ############## 
# # sudo
# ############## 
#
# sudo 成功
# Jun 15 11:39:46 vagrant-centos65 sudo:  vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/usr/bin/tail -f /var/log/secure
#
# sudo 失敗
# Jun 15 12:11:51 vagrant-centos65 sudo: pam_unix(sudo:auth): authentication failure; logname=vagrant uid=500 euid=0 tty=/dev/pts/1 ruser=vagrant rhost=  user=vagrant
# Jun 15 12:11:57 vagrant-centos65 sudo:  vagrant : 3 incorrect password attempts ; TTY=pts/1 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/ls
#
# sudoers にいない
# Jun 15 12:06:28 vagrant-centos65 sudo:  vagrant : user NOT in sudoers ; TTY=pts/1 ; PWD=/home/vagrant ; USER=root ; COMMAND=/usr/sbin/visudo
#
# su 実行
# Jun 15 12:05:54 vagrant-centos65 su: pam_unix(su:session): session opened for user root by vagrant(uid=500)
#
