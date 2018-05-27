defmodule Factor.Listener do
  use GenServer

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end
  @port 30000
  def init(_state) do
    {:ok, port} = :gen_tcp.listen(@port, [{:active, :true}, 
                                          {:reuseaddr, :true}])
    :error_logger.info_report(port)
    {:ok, port}
  end
  def connect(child, port) do
    case :gen_tcp.controlling_process(port, child) do
      :ok -> :error_logger.info_report({"ok", port, child})
        :ok
      x -> :error_logger.info_report(x)
    end
  end
  def handle_cast({:closed, port}, state) do
    :error_logger.info_report({:listener1, :closed, port})
    ret = Supervisor.terminate_child(:factor_sup, port)
    :error_logger.info_report({:listener, :closed, ret})
    {:noreply, state}
  end
  def handle_cast({:accepted, worker_pid, port, master, factor}, state) do
    :inet.setopts(port, [{:packet, :line}, :binary])
    :ok = :gen_tcp.controlling_process(port, worker_pid)
    {:noreply, state}
  end
  def handle_cast({:accept, super_ref, accepted}, state) do
    :error_logger.info_report(:accept)
    {:ok, port} = :gen_tcp.accept(state)
    apply(accepted, [super_ref, port]) 
    {:noreply, state}
  end
  def handle_info(n, state) do
    :error_logger.info_report({:listener, n, state})
    {:noreply,  state}
  end
end
