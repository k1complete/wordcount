defmodule Factor.Supervisor do
#  use Supervisor
  use Supervisor
  import Supervisor.Spec
  def start_link(arg) do
    IO.inspect [arg]
    {:ok, ret} = Supervisor.start_link(__MODULE__, arg)
    IO.inspect [supervisor: ret]
#    r = :supervisor.get_childspec(ret, arg)
#    IO.inspect [__MODULE__, r]
    {:ok, ret}
  end
  def init(a) do
    {:ok, {{:rest_for_one,
            10,
            100},
           []}}
  end
  def start_child({listener, port, sup_ref, master}) do
    childspec = {{port, FactorServer},
                  {Factor.Server, :start_link, [{}]},
                  :temporary,
                  100_000,
                  :worker,
                  [Factor.Server]}
    {:ok, factor} = Supervisor.start_child(sup_ref, childspec)
    args = {listener, port, sup_ref, master, factor}
    childspec = {{port, Factor.TcpServer},
                  {Factor.TcpServer, :start_link, [args]},
                  :temporary,
                  100_000,
                  :worker,
                  [Factor.TcpServer]}
    {:ok, tcp} = Supervisor.start_child(sup_ref, childspec)
    :ok
  end
end
