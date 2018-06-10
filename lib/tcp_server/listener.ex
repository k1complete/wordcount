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
    GenServer.cast(state.name, {:accept, state.supervisor, state.accepter, state.name})
    #:error_logger.info_report({:cast, state})
    {:ok, state}
  end
  def start_accepter(sup_pid, listener, listener_socket, accepter, listener_pid) do
    spawn_link(fn() ->
      {:ok, socket} = :gen_tcp.accept(listener_socket)
      :ok = :gen_tcp.controlling_process(socket, :erlang.whereis(listener))
      apply(accepter, [sup_pid, socket, listener_pid])
      GenServer.cast(listener, {:accept, sup_pid, accepter, listener_pid})
    end)
  end
  def handle_cast({:accept, super_ref, accepted, listener}, state) do
    start_accepter(super_ref, state.name, state.port, accepted, listener)
    {:noreply, state}
  end
  def handle_call({:take_socket, socket, pid}, _from, state) do
    ret = :gen_tcp.controlling_process(socket, pid)
    {:reply, ret, state}
  end
  def handle_call({:delete_child, super_ref, child_id}, _from, state) do
    :error_logger.info_report({:master_delete_child0, super_ref, child_id})
    ret1 = Supervisor.terminate_child(super_ref, child_id)
    :error_logger.info_report({:master_delete_child1, super_ref, child_id, ret1})
    ret2 = Supervisor.delete_child(super_ref, child_id)
    :error_logger.info_report({:master_delete_child2, super_ref, child_id, ret2})
    {:reply, {:ok, ret1, ret2}, state}
  end
  def save_socket(port, listener) when is_atom(listener) do
    :ok = :inet.setopts(port, [active: :false])
    lpid = :erlang.whereis(listener)
    :ok = :gen_tcp.controlling_process(port, lpid)
  end
end
