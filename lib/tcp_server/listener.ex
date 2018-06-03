defmodule TcpServer.Listener do
  use GenServer

  def start_link(state, opts \\ []) do
    state = Map.put(state, :name, opts[:name])
    GenServer.start_link(__MODULE__, state, opts)
  end
  @port 30000
  def init(state) do
    {:ok, port} = :gen_tcp.listen(@port, [{:active, :false},
                                          {:reuseaddr, :true}])
    :error_logger.info_report(port)
    state = Map.put(state, :port, port)
    GenServer.cast(state.name, {:accept, state.supervisor, state.accepter})
    {:ok, state}
  end
  def connect(child, port) do
    case :gen_tcp.controlling_process(port, child) do
      :ok -> :error_logger.info_report({"ok", port, child, self()})
        :ok
      x -> :error_logger.info_report(x)
    end
  end
  def start_accepter(sup_pid, listener, listener_socket, accepter) do
    spawn_link(fn() ->
        case :gen_tcp.accept(listener_socket) do
          {:ok, socket} ->
            :ok = :gen_tcp.controlling_process(socket, :erlang.whereis(listener))
            apply(accepter, [sup_pid, socket])
            GenServer.cast(listener, {:accept, sup_pid, accepter})
          {:error, :closed} ->
            :error_logger.info_report({:listener, :closed})
            exit({:error, :closed})
          x ->
            :error_logger.info_report({:listener, x})
        end
    end)
  end
  def handle_call({:take_socket, socket, pid}, _from, state) do
    ret = :gen_tcp.controlling_process(socket, pid)
    {:reply, ret, state}
  end
  def handle_cast({:closed, port}, state) do
    :error_logger.info_report({:listener1, :closed, port})
    ret = Supervisor.terminate_child(:factor_sup, port)
    :error_logger.info_report({:listener, :closed, ret})
    {:noreply, state}
  end
  def handle_cast({:accept, super_ref, accepted}, state) do
    start_accepter(super_ref, state.name, state.port, accepted)
#
#    :error_logger.info_report({:accept, super_ref, accepted})
#    {:ok, port} = :gen_tcp.accept(state)
#    :error_logger.info_report({:accept2, super_ref, accepted})
#    apply(accepted, [super_ref, port]) 
    {:noreply, state}
  end
  def handle_info({:tcp_closed, socket}, state) do
    :error_logger.info_report({:listener, socket, state})
    :gen_tcp.close(socket)
    {:noreply,  state}
  end
  def handle_info(n, state) do
    :error_logger.info_report({:listener, n, state})
    {:noreply,  state}
  end
  def terminate(reason, state) do
    :error_logger.info_report({:terminate, reason, state})
    reason
  end
end
