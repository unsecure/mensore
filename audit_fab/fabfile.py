#vim: fileencoding=utf8:
import ConfigParser
from fabric.api import run, sudo, put, local, env, cd, execute
from fabric.contrib.files import exists
from fabric.contrib.project import rsync_project
from fabric.decorators import task, roles

DIR_BASE = '/tmp/mensore'

DIR_LIB = DIR_BASE + '/lib'
DIR_LOG_COLLECTOR = DIR_BASE + '/log_collector'
DIR_DATA_COLLECTOR = DIR_BASE + '/data_collector'
DIR_MONITORING = DIR_BASE + '/monitoring'

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
audit_server = inifile.get("host", "audit_server").split(",")
audit_client = inifile.get("host", "audit_client").split(",")
env.roledefs = {
	'audit_server': audit_server,
	'audit_client': audit_client
}

"""
サーバー
"""

@roles("audit_server")
def deploy_server():
    run("hostname")
    __deploy_mensore()

@roles("audit_server")
def start_server():
    with cd(DIR_LOG_COLLECTOR):
        sudo("LANG=C ./server.pl")
    with cd(DIR_DATA_COLLECTOR):
        sudo("LANG=C ./server.pl")
    with cd(DIR_MONITORING):
        pass

@roles("audit_server")
def stop_server():
    with cd(DIR_LOG_COLLECTOR):
        sudo("kill -TERM `cat pid`")
    with cd(DIR_DATA_COLLECTOR):
        sudo("kill -TERM `cat pid`")
    with cd(DIR_MONITORING):
        pass

"""
クライアント
"""

@roles("audit_client")
def deploy_client():
    run("hostname")
    __deploy_mensore()

@roles("audit_client")
def start_client():
    with cd(DIR_LOG_COLLECTOR):
        sudo("LANG=C ./client.pl files.txt")
    with cd(DIR_LOG_COLLECTOR_SECURE_LOG):
        sudo("LANG=C ./secure_logger.pl")
    with cd(DIR_MONITORING):
        pass

@roles("audit_client")
def stop_client():
    with cd(DIR_LOG_COLLECTOR):
        sudo("kill -TERM `cat pid`")
    with cd(DIR_LOG_COLLECTOR_SECURE_LOG):
        sudo("kill -TERM `cat pid`")
    with cd(DIR_MONITORING):
        pass

"""
内部関数
"""

@roles("audit_server", "audit_client")
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
