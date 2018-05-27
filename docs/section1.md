# Elixirの特徴

## 例題

ワードカウントするプログラムをElixirらしくなくかいてみる

{:ok, content} = File.read(file)
lines = String.split(content, [" ", "\n"])
result = %{}
for x in lines do
    result = Map.update(result, x, 1, &(&1 + 1))
end
Enum.to_list(result)

## パイプライン演算子

|> で関数を繋ぐことができる。
例でみると
 
    iex> String.upcase("a,b,c")
    ...> |> String.split(",")
    ["A", "B", "C"]
 
これは、以下の処理と同じ

    iex> String.split(String.upcase("abc"), ",")
    ["A", "B", "C"]

## Stream

|>は便利だが、欠点もある

    iex> [1, 2, 3] |>
    ...  Enum.map(fn(x) -> x * x end) |>
    ...  Enum.map(fn(x) -> x + 1 end)
    [2, 5, 10]

この処理の効率を考えてみる。リストに対してEnum.map/2を
2回しているので、リストの長さnに対して2nだけ計算している。
また、リストを明示的に作っているため中間結果のリストが不要に
作られてしまっている。これでは大きなリストに対してはメモリを
使いすぎてしまう。

    iex> [1, 2, 3] |>
    ...  Enum.map(fn(x) -> x * x + 1 end)
    [2, 5, 10]

こうすると最適となるが、処理が中に埋め込まれてしまっていて
可搬性が損われている。また、リスト全体がメモリになくてはならない。

Streamを使うことで、この「何度もリストをトラバースする」
「リスト全体のコピーが必要」という部分を改善することができる。

    iex> m = [1, 2, 3] |>
    ...  Stream.map(fn(x) -> x * x end) |>
    ...  Stream.map(fn(x) -> x + 1 end) 
    #Stream<[enum: [1, 2, 3],
      funs: [#Function<46.40091930/1 in Stream.map/2>,
        #Function<46.40091930/1 in Stream.map/2>]]>

EnumをStreamに替えると、Stream structが返って来る。
これをEnum.to_list/1に渡すと実体化される。

    iex> m |> Enum.to_list()
    [2, 5, 10]

計算はこのEnum.to_list/1から呼び出される毎に各関数が
呼ばれて値の計算が行われる。
つまり、一度に一要素分だけの計算スペースがあれば
よい(最後にリストにするのでその分はどうしようもないが)。

Streamは強力で多用されるが、まだ問題点が残っている。
それは、「マルチコアCPUの能力を使い切っていない」という点。

## Flow

マルチコアCPUの能力を使い切るためにStreamに加えて何が必要だろう。

* 処理のマルチプロセスへの分散化
* 処理結果の統合

いわゆるmap-reduceにあたるフレームワークだが、これだけでいいのだろうか。
効果的にコアを使うためには、

* 各プロセスの要求に応じた処理の配分プロトコル
* プロセス間通信量の最小化

が必要だ。
これを行うビヘイビアがGenStageで、それをStreamへ適用したのがFlowとなる。

## 測定コーナー

input file: example.gz
line:    4,280,614
word:   19,938,949
char:  134,666,830

solve0 311
solve1 361
solve2 173
solve3 64
solve4 56
solve5 22

[{:method, :solve0, :size, "", :msec, 301437683},
 {:method, :solve0, :size, "_1m", :msec, 39063220},
 {:method, :solve0, :size, "_100k", :msec, 2885465},
 {:method, :solve0, :size, "_10k", :msec, 157585},
 {:method, :solve0, :size, "_1k", :msec, 7918},
 {:method, :solve1, :size, "", :msec, 297628128},
 {:method, :solve1, :size, "_1m", :msec, 37075575},
 {:method, :solve1, :size, "_100k", :msec, 2832625},
 {:method, :solve1, :size, "_10k", :msec, 165490},
 {:method, :solve1, :size, "_1k", :msec, 7204},
 {:method, :solve2, :size, "", :msec, 157497579},
 {:method, :solve2, :size, "_1m", :msec, 35987245},
 {:method, :solve2, :size, "_100k", :msec, 1437536},
 {:method, :solve2, :size, "_10k", :msec, 120952},
 {:method, :solve2, :size, "_1k", :msec, 8398},
 {:method, :solve3, :size, "", :msec, 57132489},
 {:method, :solve3, :size, "_1m", :msec, 13193480},
 {:method, :solve3, :size, "_100k", :msec, 1456387},
 {:method, :solve3, :size, "_10k", :msec, 132689},
 {:method, :solve3, :size, "_1k", :msec, 15394},
 {:method, :solve4, :size, "", :msec, 58212160},
 {:method, :solve4, :size, "_1m", :msec, 11269317},
 {:method, :solve4, :size, "_100k", :msec, 1274524},
 {:method, :solve4, :size, "_10k", :msec, 121054},
 {:method, :solve4, :size, "_1k", :msec, 17902},
 {:method, :solve5, :size, "", :msec, 22571693},
 {:method, :solve5, :size, "_1m", :msec, 6884290},
 {:method, :solve5, :size, "_100k", :msec, 980041},
 {:method, :solve5, :size, "_10k", :msec, 93040},
 {:method, :solve5, :size, "_1k", :msec, 16682}]

## OTPフレームワーク

Elixirは基盤となっているErlangの実行時システムに付属しているOTP(Open
Telecom Platform)と呼ばれるフレームワークを利用することができる。

OTPはErlangの開発元であるEricssonが自社の電話交換機システムに
必要と考えた機能群が注意深く抽象化されて盛り込まれている。

+ GenServer: サーバ機能
+ Supervisor: プロセスツリーの構成と監視、再起動機能
+ Statem: ステートマシン
+ Application: OTPアプリケーションとして起動、停止、などの共通機能
+ Mnesia: 分散データベース
  ...

またOTPは特定のディレクトリ構成を要求しているが、これはmix new <プロジェ
クト名> というコマンドで自動的に作成される。事実上実用的な全てのElixir
プログラムはOTPアプリケーションとして作成される。OTPアプリケーションに
は、いわゆるライブラリも含まれ、OTPアプリケーションを複数組み合わせてよ
り大きなアプリケーションを構築することが普通である。

### 例題: 素因数分解アプリケーション

素因数分解をTCP/IPコネクション上で行うプログラムをOTPアプリケーション
として構築することを通じて、GenServerやSupervisor, Applicationといった
OTPの使いかたをみてみる。

#### 要求条件

+ 30000/TCPでListenする
+ プロトコルは
  C->S: 数字列\r\n       : 素因数分解してほしい数値
  S->C: \[ 数字列+ \]              : 素数の場合の応答
      | \[ 数字列+ (, 数字列)+ \]  : 素因数のリスト(同じ素因数は必要なだけリストする)
  C->S: quit\r\n         : 終了
  S->C: {TCP-close}      : クローズ
  C->S: {TCP-close}      : クライアントからクローズ

+ 複数のクライアントを同時に処理できること
+ 実行時に無停止で機能変更が出来ること

#### 設計

アプリケーションを


## 計算に対する研究と実務

アルゴリズムに関する研究はコンピュータの発明以前からされてきていた。そ
の中で既に万能テューリングマシンや計算可能性に関する研究の成果が認識さ
れていた。停止性問題は1936年にテューリングによって証明されている。

一方、ノイマンらによって発明されたストアドプログラム方式のコンピュータ
は機械語によるプログラミングから始まり、軌道計算や事務処理のために使わ
れて来た。
世界初のコンパイラはバッカスによる1957年のFORTRANとされている。
COBOLを発明したのが優美なバッタだったが、そのコンパイラが動かなかったた
め、バグと呼ばれるようになった。(本当はグレースホッパー氏が1944年頃マー
クIIと呼ばれたリレー式コンピュータ開発時にリレーに蛾が挟まって動かなく
なったことを「実際にバグがみつかった初めての例」と日誌に書き込んだ故事
に基く。何れにしてもコンピュータ発明以前から電気関係の不具合をバグと呼
んでいた)


