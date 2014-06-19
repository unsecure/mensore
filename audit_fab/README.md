設定
====

config.ini にユーザ情報や環境構築対象ホストの情報を記述する

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

