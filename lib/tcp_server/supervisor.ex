defmodule TcpServer.Supervisor do
  use Supervisor

  def start_link(arg) do
    IO.inspect [arg]
    {:ok, ret} = Supervisor.start_link(__MODULE__, arg)
    IO.inspect [supervisor: ret]
    {:ok, ret}
  end
  def init(_a) do
    {:ok, {{:one_for_all,
            10,
            100},
           []}}
  end
  def start_child({listener, port, sup_ref, master}) do
    childspec = worker(Factor.Server, [{}], 
      [id: {port, Factor.Server},
       restart: :transient,
       shutdown: 100_000])
    {:ok, factor} = Supervisor.start_child(sup_ref, childspec)
    args = {listener, port, sup_ref, master, {port, Factor.Server}}
    childspec = worker(Factor.UserSession, [args],
      [id: {port, Factor.UserSession},
       restart: :transient,
       shutdown: 100_000])
    {:ok, tcp} = Supervisor.start_child(sup_ref, childspec)
    :error_logger.info_report({:child, factor, tcp})
    :ok
  end
end
