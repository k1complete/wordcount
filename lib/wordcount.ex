#alias GenStage.Flow
defmodule Wordcount do
  @moduledoc """
  Documentation for Wordcount.
  """

  @doc """
  Word count solve0
  
  Example:

      iex> Wordcount.solve0("example_test") |> Enum.sort()
      [{"This", 1}, {"a", 2}, {"example", 1}, {"file.", 1},
       {"is", 2}, {"sample.", 1}, {"this", 1}]

  """
  def solve0(file) do
    {:ok, content} = File.read(file)
    lines = String.split(content, "\n")
    words = Enum.flat_map(lines, 
      fn(line) ->
        String.split(line, " ")
      end)
    result = Enum.reduce(words, %{}, 
      fn(word, acc) -> 
        Map.update(acc, word, 1, &(&1 + 1)) 
      end)
    Enum.to_list(result)
  end
  @doc """
  Word count solve1
  
  Example:

      iex> Wordcount.solve1("example_test") |> Enum.sort()
      [{"This", 1}, {"a", 2}, {"example", 1}, {"file.", 1},
       {"is", 2}, {"sample.", 1}, {"this", 1}]

  """
  def solve1(file) do
    File.read!(file)
    |> String.split("\n")
    |> Enum.flat_map(fn(line) ->
         String.split(line, " ")
       end)
    |> Enum.reduce(%{}, fn(word, acc) ->
         Map.update(acc, word, 1, &(&1 + 1))
       end)
    |> Enum.to_list()
  end
  @doc """
  Word count solve2
  
  Example:

      iex> Wordcount.solve2("example_test") |> Enum.sort()
      [{"This", 1}, {"a", 2}, {"example", 1}, {"file.", 1},
       {"is", 2}, {"sample.", 1}, {"this", 1}]

  """
  def solve2(file) do
    File.stream!(file)
    |> Stream.flat_map(fn(line) ->
         String.split(line, [" ", "\n"])
       end)
    |> Enum.reduce(%{}, 
       fn("", acc) ->  acc
         (word, acc) -> Map.update(acc, word, 1, &(&1 + 1))
       end)
    |> Enum.to_list()
  end
  @doc """
  Word count solve3
  
  Example:

      iex> Wordcount.solve3("example_test") |> Enum.sort()
      [{"This", 1}, {"a", 2}, {"example", 1}, {"file.", 1},
       {"is", 2}, {"sample.", 1}, {"this", 1}]

  """
  def solve3(file) do
    File.stream!(file)
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn(line) ->
         for word <- String.split(line, [" ", "\n"]), do: word
       end)
    |> Flow.partition()
    |> Flow.reduce(fn() -> %{} end, 
       fn("", acc) ->  acc
         (word, acc) -> Map.update(acc, word, 1, &(&1 + 1))
       end)
    |> Enum.to_list()
  end
  @doc """
  Word count solve4
  
  Example:

      iex> Wordcount.solve4("example_test") |> Enum.sort()
      [{"This", 1}, {"a", 2}, {"example", 1}, {"file.", 1},
       {"is", 2}, {"sample.", 1}, {"this", 1}]

  """
  def solve4(file) do
    pattern = :binary.compile_pattern([" ", "\n"])
    File.stream!(file)
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn(line) ->
         for word <- String.split(line, pattern), do: word
       end)
    |> Flow.partition()
    |> Flow.reduce(fn() -> %{} end, 
       fn("", acc) ->  acc
         (word, acc) -> Map.update(acc, word, 1, &(&1 + 1))
       end)
    |> Enum.to_list()
  end
  @doc """
  Word count solve5
  
  Example:

      iex> Wordcount.solve5("example_test") |> Enum.sort()
      [{"This", 1}, {"a", 2}, {"example", 1}, {"file.", 1},
       {"is", 2}, {"sample.", 1}, {"this", 1}]

  """
  def solve5(file) do
    parent = self()
    pattern = :binary.compile_pattern([" ", "\n"])
    File.stream!(file)
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn(line) ->
         for word <- String.split(line, pattern), do: word
       end)
    |> Flow.partition()
    |> Flow.reduce(fn() -> :ets.new(:words, []) end, 
       fn("", ets) -> ets
         (word, ets) ->
           :ets.update_counter(ets, word, {2, 1}, {word, 0})
           ets
       end)
    |> Flow.map_state(fn(ets) ->
         :ets.give_away(ets, parent, [])
         [ets]
       end)
    |> Enum.flat_map(&(:ets.tab2list(&1)))
  end
  @afile "/usr/share/dict/web2"
  def prof_analyse(mod, func) do
    :fprof.start()
    :fprof.apply(mod, func, [@afile])
    :fprof.profile()
    :fprof.analyse()
  end
  def measures() do
    m = fn(s, f) ->
      a = System.system_time; 
      apply(Wordcount, s, ["example#{f}"])
      b = System.system_time; 
      IO.inspect [s, f, b - a]
      {:method, s, :size, f, :msec, :erlang.convert_time_unit(b - a, :native, :microsecond)}
    end
    ret = for x <- 0..5, f <- ["", "_1m", "_100k", "_10k", "_1k"] do
        m.(:"solve#{x}", f)
    end
    IO.inspect ret
  end
end
