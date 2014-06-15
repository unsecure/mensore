#vim: fileencoding=utf8:
import ConfigParser
from fabric.api import run, sudo, put, local, env, cd, execute
from fabric.contrib.files import exists
from fabric.decorators import task, roles

DIR_BASE = '/tmp'
DIR_LOG_COLLECTOR = DIR_BASE + '/log_collector'
DIR_LOG_COLLECTOR_LIB = DIR_LOG_COLLECTOR + '/lib'
DIR_LOG_COLLECTOR_LIB_FILE = DIR_LOG_COLLECTOR_LIB + '/File'
DIR_LOG_COLLECTOR_LIB_TIME = DIR_LOG_COLLECTOR_LIB + '/Time'
DIR_LOG_COLLECTOR_SECURE_LOG = DIR_LOG_COLLECTOR + '/secure_log'
DIR_DATA_COLLECTOR = DIR_BASE + '/data_collector'
DIR_MONITORING = DIR_BASE + '/monitoring'

@task
def all():
    """
    全実行
    """
    __init()
    execute(__setting_audit_server)
    execute(__setting_audit_client)


@task
def client():
    """
    監視クライアント
    """
    __init()
    execute(__setting_audit_client)


@task
def server():
    """
    監視サーバ
    """
    __init()
    execute(__setting_audit_server)


"""

内部関数

"""

def __init():
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
    pprint(env.roledefs)


@roles("audit_server")
def __setting_audit_server():
    """
    監視サーバを起動
    """
    run("hostname")
    __deploy_mensore()

    # 監視サーバスクリプト実行
    with cd(DIR_LOG_COLLECTOR):
        sudo("LC_ALL=en_US.UTF-8 ./server.pl &")
    with cd(DIR_DATA_COLLECTOR):
        sudo("LC_ALL=en_US.UTF-8 ./server.pl &")
    with cd(DIR_MONITORING):
        pass


@roles("audit_client")
def __setting_audit_client():
    """
    監視クライアントサーバを起動
    """
    run("hostname")
    __deploy_mensore()

    # クライアントスクリプト実行
    with cd(DIR_LOG_COLLECTOR):
        sudo("LC_ALL=en_US.UTF-8 ./client.pl files.txt &")
    with cd(DIR_LOG_COLLECTOR_SECURE_LOG):
        sudo("LC_ALL=en_US.UTF-8 ./secure_logger.pl &")
    with cd(DIR_DATA_COLLECTOR):
        sudo("ps aux | LC_ALL=en_US.UTF-8 ./client.pl ps &")
    with cd(DIR_MONITORING):
        pass


@roles("audit_server", "audit_client")
def __deploy_mensore():
    """
    全スクリプトの配布
    """
    # log_collector 配布
    __deploy_log_collector()
    # data_collector 配布
    __deploy_data_collector()
    # monitoring 配布
    __deploy_monitoring()


@roles("audit_server", "audit_client")
def __deploy_log_collector():
    """
    log_collector の配布
    """
    if not exists(DIR_LOG_COLLECTOR):
        run("mkdir %s" % DIR_LOG_COLLECTOR)
    if not exists(DIR_LOG_COLLECTOR_LIB):
        run('mkdir %s' % (DIR_LOG_COLLECTOR_LIB))
    if not exists(DIR_LOG_COLLECTOR_LIB_FILE):
        run("mkdir %s" % (DIR_LOG_COLLECTOR_LIB_FILE))
    if not exists(DIR_LOG_COLLECTOR_LIB_TIME):
        run("mkdir %s" % (DIR_LOG_COLLECTOR_LIB_TIME))
    if not exists(DIR_LOG_COLLECTOR_SECURE_LOG):
        run("mkdir %s" % (DIR_LOG_COLLECTOR_SECURE_LOG))

    put("../log_collector/client.pl", "%s/client.pl" % (DIR_LOG_COLLECTOR), mirror_local_mode=True)
    put("../log_collector/files.txt", "%s/files.txt" % (DIR_LOG_COLLECTOR), mirror_local_mode=True)
    put("../log_collector/server.pl", "%s/server.pl" % (DIR_LOG_COLLECTOR), mirror_local_mode=True)
    put("../log_collector/lib/File/Tail.pm", "%s/Tail.pm" % (DIR_LOG_COLLECTOR_LIB_FILE), mirror_local_mode=True)
    put("../log_collector/lib/Time/HiRes.pm", "%s/HiRes.pm" % (DIR_LOG_COLLECTOR_LIB_TIME), mirror_local_mode=True)
    put("../log_collector/secure_log/secure_logger.pl", "%s/secure_logger.pl" % (DIR_LOG_COLLECTOR_SECURE_LOG), mirror_local_mode=True)


@roles("audit_server", "audit_client")
def __deploy_data_collector():
    """
    data_collector の配布
    """
    if not exists(DIR_DATA_COLLECTOR):
        run("mkdir %s" % DIR_DATA_COLLECTOR)

    put("../data_collector/client.pl", "%s/client.pl" % (DIR_DATA_COLLECTOR), mirror_local_mode=True)
    put("../data_collector/server.pl", "%s/server.pl" % (DIR_DATA_COLLECTOR), mirror_local_mode=True)


@roles("audit_server", "audit_client")
def __deploy_monitoring():
    """
    monitoring の配布
    """
    if not exists(DIR_MONITORING):
        run("mkdir %s" % DIR_MONITORING)

    put("../monitoring/check-http.pl", "%s/check-http.pl" % (DIR_MONITORING), mirror_local_mode=True)
    put("../monitoring/check-load.pl", "%s/check-load.pl" % (DIR_MONITORING), mirror_local_mode=True)
    put("../monitoring/check-ping.pl", "%s/check-ping.pl" % (DIR_MONITORING), mirror_local_mode=True)
    put("../monitoring/defacement-detector.pl", "%s/defacement-detector.pl" % (DIR_MONITORING), mirror_local_mode=True)
    put("../monitoring/hosts.txt", "%s/hosts.txt" % (DIR_MONITORING), mirror_local_mode=True)
    put("../monitoring/load.txt", "%s/load.txt" % (DIR_MONITORING), mirror_local_mode=True)
    put("../monitoring/urls.txt", "%s/urls.txt" % (DIR_MONITORING), mirror_local_mode=True)
