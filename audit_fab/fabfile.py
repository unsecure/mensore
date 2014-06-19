#vim: fileencoding=utf8:
import ConfigParser
import os
from fabric.api import run, sudo, put, local, env, cd, execute
from fabric.contrib.files import exists
from fabric.contrib.project import rsync_project
from fabric.decorators import task, roles

DIR_BASE = '/tmp/mensore'

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

# ホストの設定
server = inifile.get("host", "server").split(",")
client = inifile.get("host", "client").split(",")
env.roledefs = {
	'server': server,
	'client': client
}

"""
サーバー
"""

@roles("server")
def deploy_server():
    __deploy_mensore()

@roles("server")
def start_server():

    run("touch %s" % DIR_LOGS + "/server.log")

    with cd(DIR_LOG_COLLECTOR):
        sudo("LANG=C ./server.pl %s" % DIR_LOGS + "/server.log")
    with cd(DIR_DATA_COLLECTOR):
        sudo("LANG=C ./server.pl %s" % DIR_DATA )

	__gen_server_cron()
    put('server.cron', DIR_BASE + "/server.cron")
    sudo("mv %s %s" % (DIR_BASE + "/server.cron", DIR_CRON + "/mensore-server"))
    sudo("chown root:root %s" % DIR_CRON + "/mensore-server")
    sudo("chmod 644 %s" % DIR_CRON + "/mensore-server")

@roles("server")
def stop_server():
    with cd(DIR_LOG_COLLECTOR):
        sudo("kill -TERM `cat pid`")
    with cd(DIR_DATA_COLLECTOR):
        sudo("kill -TERM `cat pid`")

    # cronの設定
    sudo("rm %s" % DIR_CRON + "/mensore-server")

@roles("server")
def clean_server():
    __clean_mensore()

"""
クライアント
"""

@roles("client")
def deploy_client():
    __deploy_mensore()

@roles("client")
def start_client():

    run("touch %s" % DIR_LOGS + "/client.log");

    with cd(DIR_LOG_COLLECTOR):
        sudo("LANG=C ./client.pl %s files.txt" % server[0])
    with cd(DIR_MONITORING+"/client"):
        sudo("LANG=C ./secure.pl %s" % DIR_LOGS + "/client.log")

    # cronの設定
	__gen_client_cron()
    put('client.cron', DIR_BASE + "/client.cron")
    sudo("mv %s %s" % (DIR_BASE + "/client.cron", DIR_CRON + "/mensore-client"))
    sudo("chown root:root %s" % DIR_CRON + "/mensore-client")
    sudo("chmod 644 %s" % DIR_CRON + "/mensore-client")

@roles("client")
def stop_client():
    with cd(DIR_LOG_COLLECTOR):
        sudo("kill -TERM `cat pid`")
    with cd(DIR_MONITORING+"/client"):
        sudo("kill -TERM `cat secure.pid`")

    # cronの設定
    sudo("rm %s" % DIR_CRON + "/mensore-client")

@roles("client")
def clean_client():
    __clean_mensore()

"""
内部関数
"""

@roles("server", "client")
def __deploy_mensore():
    """
    全スクリプトの配布
    """

    run("mkdir -p %s" % DIR_BASE)

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

    # サーバー
    os.system("echo %s > server" % server[0])
    put('server', DIR_BASE + "/server")

@roles("server", "client")
def __clean_mensore():

    sudo("rm -rf %s" % DIR_BASE)

def __gen_server_cron():

    f = open('server.cron', 'w')

    CRON = ""
    CRON += "*/5 * * * * root cd /tmp/mensore/monitoring/server/ && ./check-ping.pl hosts.txt | nc localhost 6666\n";
    CRON += "*/5 * * * * root cd /tmp/mensore/monitoring/server/ && ./check-http.pl urls.txt | nc localhost 6666\n";

    f.write(CRON)
    f.close()

def __gen_client_cron():

    f = open('client.cron', 'w')

    CRON = ""
    CRON += "*/5 * * * * root cd /tmp/mensore/monitoring/client/ && ./check-load.pl load.txt >> " + DIR_LOGS + "/client.log\n"
    CRON += "*/5 * * * * root cd /tmp/mensore/monitoring/client/ && ./cron.pl | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " cron\n";
    CRON += "*/5 * * * * root cd /tmp/mensore/monitoring/client/ && ./at.pl | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " at\n";

    CRON += "*/5 * * * * root ps aux        | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " ps\n";
    CRON += "*/5 * * * * root netstat -atnp | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " netstat\n"
    CRON += "*/5 * * * * root last -n 50    | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " last\n"
    CRON += "*/5 * * * * root w             | " + DATA_COLLECTOR_CLIENT + " " + server[0] + " w\n"
    
    f.write(CRON)
    f.close()

