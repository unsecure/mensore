設定
====

config.ini にユーザ情報や環境構築対象ホストの情報を記述する

* ポートフォワードじゃない場合
```
[host]
portforwarded = 0
server = 192.168.33.11
client = 192.168.33.12,192.168.33.11
```

* ポートフォワードの場合 (server と client はフォワードしているホストを指定)
```
[host]
portforwarded = 1
server = 127.0.0.1
client = 127.0.0.1
server_port = 10001
client_port = 10001, 10002
```

====

* サーバ全台に mensore ユーザを作成
```
fab add_mensore
```

* 監視サーバ環境構築

```
fab deploy_server
```

* 監視サーバ起動＆終了

```
fab start_server
fab stop_server
```

* 監視クライアント環境構築

```
fab deploy_client
```

* 監視クライアント起動＆終了

```
fab start_client
fab stop_client
```

