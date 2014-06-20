#vim: fileencoding=utf8:
import ConfigParser
import os
import sys
from fabric.api import run, sudo, put, local, env, cd, execute
from fabric.contrib.files import exists
from fabric.contrib.project import rsync_project
from fabric.decorators import task, roles

DIR_BASE = '/home/mensore'

DIR_LIB = DIR_BASE + '/lib'
DIR_LOG_COLLECTOR = DIR_BASE + '/log_collector'
DIR_DATA_COLLECTOR = DIR_BASE + '/data_collector'
DIR_MONITORING = DIR_BASE + '/monitoring'
DIR_LOGS = DIR_BASE + '/logs'
DIR_DATA = DIR_BASE + '/data'
DIR_CRON = '/etc/cron.d'

DATA_COLLECTOR_CLIENT = DIR_DATA_COLLECTOR + "/client.pl"

"""
初期化
"""

# 設定ファイルの読み込み
inifile = ConfigParser.SafeConfigParser()
inifile.read("./config.ini")

# ユーザの設定
env.user = inifile.get("user", "name")
env.password = inifile.get("user", "passwd")
env.key_filename = inifile.get("user", "id_rsa")

# デフォルトユーザの設定
default_users = inifile.get("default_user", "name").split(",")
default_passwords = inifile.get("default_user", "passwd").split(",")

# ホストの設定
portforwarded = int(inifile.get("host", "portforwarded"))
server = inifile.get("host", "server").split(",")
client = inifile.get("host", "client").split(",")

# ポートフォワードならポートも取得
if portforwarded:
    server_port = inifile.get("host", "server_port").split(",")
    client_port = inifile.get("host", "client_port").split(",")
    all_port = list(set(server_port).union(set(client_port)))

env.roledefs = {
	'server': server,
	'client': client
}

"""
全環境
"""

@roles("server", "client")
def add_mensore():
    if portforwarded:
        for port in all_port:
            env.port = port
            __add_mensore()
    else:
        __add_mensore()

def __add_mensore():
    # 実行ユーザをデフォルトユーザの一人に変更
    env.user = default_users[0]
    env.password = default_passwords[0]
    new_user = inifile.get("user", "name")
    new_password = inifile.get("user", "passwd")

    # mensore ユーザ作成
    sudo("adduser %s -d %s -g users -G wheel -s /bin/bash" % (new_user, DIR_BASE))
    # mensore passwd 変更
    sudo("echo -e \"%s\\n%s\" | passwd %s" % (new_password, new_password, new_user))

    try:
        # mensore が sudoers に書かれているかチェック
        sudo("fgrep mensore /etc/sudoers  | grep NOPASSWD")
    except:
        # mensore sudoers に追加
        sudo("echo -e \"mensore ALL=NOPASSWD: ALL\\n\" >> /etc/sudoers")

    env.user = new_user
    env.password = new_password
    # mensore 公開鍵配置
    with cd(DIR_BASE):
        if not exists(".ssh"):
            sudo("mkdir -p .ssh")
            sudo("chown mensore:users .ssh")
            sudo("chmod 700 .ssh")

        with cd(".ssh"):
            put("id_rsa_mensore.pub", "id_rsa_mensore.pub")
            run("cat id_rsa_mensore.pub >> authorized_keys")
            sudo("chown mensore:users authorized_keys")
            sudo("chmod 644 authorized_keys")
            put("ssh_config_mensore", "config")

    __check_mensore()

@roles("server", "client")
def passwd_mensore():
    sudo("sed -e \"s/mensore\sALL=NOPASSWD: ALL/mensore ALL=(ALL) ALL/g\" /etc/sudoers > /etc/sudoers_tmp")
    sudo("cp /etc/sudoers /etc/sudoers_old")
    sudo("cp /etc/sudoers_tmp /etc/sudoers")

@roles("server", "client")
def deploy_keys_default_users():
    # デフォルトユーザ に公開鍵配置
    if portforwarded:
        for port in all_port:
            env.port = port
            __deploy_keys_default_users()
    else:
        __deploy_keys_default_users()

def __deploy_keys_default_users():
    pass_i = 0
    for user in default_users:
        env.user = user
        env.password = default_passwords[pass_i]
        home_dir = "/home/" + user
        with cd(home_dir):
            if not exists(".ssh"):
                sudo("mkdir -p .ssh")
                sudo("chown %s:users .ssh" % user)
                sudo("chmod 700 .ssh")
            with cd(".ssh"):
                put("id_rsa_default.pub", "id_rsa_default.pub")
                run("cat id_rsa_default.pub >> authorized_keys")
                sudo("chown %s:users authorized_keys" % user)
                sudo("chmod 644 authorized_keys")
                put("ssh_config_default", "config")
        pass_i += 1;

"""
サーバー
"""

@roles("server")
def deploy_server():
    if portforwarded:
        for port in server_port:
            env.port = port
            __check_mensore()
            __deploy_mensore()
    else:
        __check_mensore()
        __deploy_mensore()

@roles("server")
def start_server():
    if portforwarded:
        for port in server_port:
            __check_mensore()
            __start_server()
    else:
        __check_mensore()
        __start_server()

def __start_server():
    run("touch %s" % DIR_LOGS + "/server.log")

    with cd(DIR_LOG_COLLECTOR):
        mensore_sudo("./server start")
    with cd(DIR_DATA_COLLECTOR):
        mensore_sudo("./server start")

	__gen_server_cron()
    put('server.cron', DIR_BASE + "/server.cron")
    sudo("mv %s %s" % (DIR_BASE + "/server.cron", DIR_CRON + "/mensore-server"))
    sudo("chown root:root %s" % DIR_CRON + "/mensore-server")
    sudo("chmod 644 %s" % DIR_CRON + "/mensore-server")

@roles("server")
def stop_server():
    if portforwarded:
        for port in server_port:
            __check_mensore()
            __stop_server()
    else:
        __check_mensore()
        __stop_server()

def __stop_server():
    with cd(DIR_LOG_COLLECTOR):
        mensore_sudo("./server stop")
    with cd(DIR_DATA_COLLECTOR):
        mensore_sudo("./server stop")

    # cronの設定
    sudo("rm %s" % DIR_CRON + "/mensore-server")

@roles("server")
def clean_server():
    if portforwarded:
        for port in server_port:
            env.port = port
            __check_mensore()
            __clean_mensore()
    else:
        __check_mensore()
        __clean_mensore()

"""
クライアント
"""

@roles("client")
def deploy_client():
    if portforwarded:
        for port in client_port:
            env.port = port
            __check_mensore()
            __deploy_mensore()
    else:
        __check_mensore()
        __deploy_mensore()

@roles("client")
def start_client():
    if portforwarded:
        for port in client_port:
            env.port = port
            __check_mensore()
            __start_client()
    else:
        __check_mensore()
        __start_client()

def __start_client():
    run("touch %s" % DIR_LOGS + "/client.log");

    with cd(DIR_LOG_COLLECTOR):
        mensore_sudo("./client start %s files.txt" % server[0])
    with cd(DIR_MONITORING+"/client"):
        mensore_sudo("./secure start %s" % DIR_LOGS + "/client.log")

    # cronの設定
	__gen_client_cron()
    put('client.cron', DIR_BASE + "/client.cron")
    sudo("mv %s %s" % (DIR_BASE + "/client.cron", DIR_CRON + "/mensore-client"))
    sudo("chown root:root %s" % DIR_CRON + "/mensore-client")
    sudo("chmod 644 %s" % DIR_CRON + "/mensore-client")

@roles("client")
def stop_client():
    if portforwarded:
        for port in client_port:
            env.port = port
            __check_mensore()
            __stop_client()
    else:
        __check_mensore()
        __stop_client()

def __stop_client():
    with cd(DIR_LOG_COLLECTOR):
        mensore_sudo("./client stop")
    with cd(DIR_MONITORING+"/client"):
        mensore_sudo("./secure stop")

    # cronの設定
    sudo("rm %s" % DIR_CRON + "/mensore-client")

@roles("client")
def clean_client():
    if portforwarded:
        for port in client_port:
            env.port = port
            __check_mensore()
            __clean_mensore()
    else:
        __check_mensore()
        __clean_mensore()

"""
内部関数
"""

def mensore_sudo(cmd):
    sudo("HOME=%s %s" % (DIR_BASE, cmd))

@roles("server", "client")
def __check_mensore():
    try:
        run("id %s" % env.user)
    except:
        sys.exit()

@roles("server", "client")
def __deploy_mensore():
    """
    全スクリプトの配布
    """

    if not exists(DIR_BASE):
        sudo("mkdir -p %s" % DIR_BASE)
        sudo("chmod 777 %s" % DIR_BASE)

    # lib 配布
    rsync_project(local_dir="../lib/", remote_dir=DIR_LIB)
    # log_collector 配布
    rsync_project(local_dir="../log_collector/", remote_dir=DIR_LOG_COLLECTOR)
    # data_collector 配布
    rsync_project(local_dir="../data_collector/", remote_dir=DIR_DATA_COLLECTOR)
    # monitoring 配布
    rsync_project(local_dir="../monitoring/", remote_dir=DIR_MONITORING)

    run("mkdir -p %s" % DIR_LOGS)
    run("mkdir -p %s" % DIR_DATA)

@roles("server", "client")
def __clean_mensore():

    sudo("rm -rf %s" % DIR_BASE)

def __gen_server_cron():

    f = open('server.cron', 'w')

    CRON = ""
    CRON += "*/5 * * * * root cd " + DIR_MONITORING + "/server/ && ./check-ping.pl hosts.txt | nc localhost 6666\n";
    CRON += "*/5 * * * * root cd " + DIR_MONITORING + "/server/ && ./check-http.pl urls.txt | nc localhost 6666\n";
    CRON += "*/5 * * * * root cd " + DIR_MONITORING + "/server/ && ./defacement-detector.pl check | nc localhost 6666\n";

    f.write(CRON)
    f.close()

def __gen_client_cron():

    f = open('client.cron', 'w')

    CRON = ""
    CRON += "*/5 * * * * root cd " + DIR_MONITORING + "/client/ && ./check-load.pl load.txt >> " + DIR_LOGS + "/client.log\n"
    CRON += "*/5 * * * * root cd " + DIR_MONITORING + "/client/ && ./cron.pl | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " cron\n";
    CRON += "*/5 * * * * root cd " + DIR_MONITORING + "/client/ && ./at.pl | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " at\n";

    CRON += "*/5 * * * * root ps auxf       | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " ps\n";
    CRON += "*/5 * * * * root netstat -atnp | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " netstat\n"
    CRON += "*/5 * * * * root last -n 50    | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " last\n"
    CRON += "*/5 * * * * root w             | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " w\n"
    
    f.write(CRON)
    f.close()

"""
チェック系
"""

def check_date():
	run("date")

def check_hostname():
	run("hostname")

def check_os():
	run("uname -a")
	if exists("/etc/redhat-release"):
		run("cat /etc/redhat-release")

def check_if():
	run("ifconfig")

def check_disk():
	run("df -H")

def check_mem():
	run("free -m")

def check_uptime():
	run("uptime")

def check_login():
	run("w")

def check_users():
	run("cat /etc/passwd")

def check_groups():
	run("cat /etc/group")

def check_ps():
	run("ps auxf")

def check_netstat():
	run("netstat -atn")

@roles("client")
def first_check():
	check_date()
	check_hostname()
	check_os()
	check_if()
	check_disk()
	check_mem()
	check_uptime()
	check_login()
	check_users()
	check_groups()
	check_ps()
	check_netstat()
