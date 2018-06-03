defmodule Factor.Server do
  use GenServer

  def start_link({}, opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {}, opts)
    {:ok, pid}
  end
  def init(state) do
    :error_logger.info_report({:factor, self()})
    {:ok, state}
  end
  def handle_call({:factor, [n]}, _from, state) do
    {:reply, calc_factor(n), state}
  end
  @tag timeout: 360000
  @doc """
  calc factor

  examples:
  
      iex> Factor.Server.calc_factor(8)
      [2,2,2]

      iex> Factor.Server.calc_factor(7)
      [7]

      iex> Factor.Server.calc_factor(184467)
      [3617, 17, 3]

  """
  @spec calc_factor(integer) :: integer
  def calc_factor(n) do
    case n do
      n when n <= 3 -> 
        [n]
      n ->
        m = div(n, 2)
        Stream.filter(2..m, &(rem(&1, 2) != 0 or &1 == 2))
        |> Enum.reduce([n], fn(x, [h|a]) ->
          case rem(h, x) do
            0 -> divall(h, x, a)
            _ -> [h|a]
          end
        end)
        |> Enum.to_list()
    end
  end
  def divall(n, n, a) do
    [n|a]
  end
  def divall(n, m, a) do
    case rem(n, m) do
      0 -> divall(div(n, m), m, [m | a])
      _x -> 
        [n|a]
    end
  end
end
