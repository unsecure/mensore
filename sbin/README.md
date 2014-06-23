sbin
====
実行されたくないコマンドを置き換えるために作ったダミーコマンドです。
本来のコマンドと置き換えるものです。

実行された場合は、デフォルトのエラーログに書き込みを行い、何もしません。

install.sh
==========

パーミッションは、以下の通りです。
- root
- 0555

以下は、動作の例です。
- /sbin/shutdown を /sbin/shutdown.ORG にコピーします。
- /sbin/shutdown を ./shutdown で上書きします。

- /sbin/shutdown と ./shutdown が同じときは、何もしません。
- /sbin/shutdown をバックアップできないときは、何もしません。
