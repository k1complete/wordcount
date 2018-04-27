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
  
solve0 311
solve1 361
solve2 173
solve3 64
solve4 56
solve5 22
