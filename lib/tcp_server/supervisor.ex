defmodule TcpServer.Supervisor do
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
    {:ok, {{:one_for_all,
            10,
            100},
           []}}
  end
  def start_child({listener, port, sup_ref, master}) do
    childspec = {{port, Factor.Server},
                  {Factor.Server, :start_link, [{}]},
                  :transient,
                  100_000,
                  :worker,
                  [Factor.Server]}
    {:ok, factor} = Supervisor.start_child(sup_ref, childspec)
    args = {listener, port, sup_ref, master, {port, Factor.Server}}
    childspec = {{port, Factor.UserSession},
                  {Factor.UserSession, :start_link, [args]},
                  :transient,
                  100_000,
                  :worker,
                  [Factor.UserSession]}
    {:ok, tcp} = Supervisor.start_child(sup_ref, childspec)
    :error_logger.info_report({:child, factor, tcp})

    :ok
  end
end
