Fabricを利用する

http://www.fabfile.org/

参考

http://shiumachi.hatenablog.com/entry/20130414/1365920515 
http://dekokun.github.io/posts/2013-04-07.html 
https://github.com/niratama/chibapm4.1/blob/master/fabric.md 

* 決まった作業をする

```
fab check_date -H 192.168.11.100
```

決まった作業はfabfile.pyに定義
ファイルを送ったり、持ってきたり、sudoを実行したり
詳細はfabricのマニュアル参照

* すべてのホストで実行する

```
fab all_host check_date
```

ホストはhosts.txtに定義
fabfile.pyを工夫することでホストをグループ化することも可能(front,db,etc)

* 指定したコマンドを実行する

```
fab all_host -- hostname
```
