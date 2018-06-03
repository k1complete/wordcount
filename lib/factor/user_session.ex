defmodule Factor.UserSession do
  use GenServer
  def start_link({listener, port, parent, master, factor}, opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {listener, port, parent, master, factor}, opts)
    {:ok, pid}
  end
  def init({listener, port, parent, master, factor}) do
    :error_logger.info_report({:us, {listener, port, parent, factor}})
    :ok = GenServer.cast(self(),
      {:setup, listener, self(), port, parent,  master, factor})
    {:ok, %{listener: listener, 
            port: port, 
            parent: parent, 
            master: master, 
            server: factor, 
            state: ""}}
  end
  def save_socket(port, listener) do
    :ok = :inet.setopts(port, [active: :false])
    lpid = case is_atom(listener) do
             true -> :erlang.whereis(listener)
             fale -> listener
           end
    :ok = :gen_tcp.controlling_process(port, lpid)
  end
  def handle_cast({:setup, listener, pid, port, parent, master, factor}, state) do
    IO.inspect({:listener, listener})
    ret = GenServer.call(listener, {:take_socket, port, pid})
    :ok = :inet.setopts(port, [active: :true, mode: :binary, packet: :line])
    m = Supervisor.which_children(parent)
    :error_logger.info_report({:server2, m})
    [m2] = Enum.filter(m, fn(e) -> elem(e, 0) == state.server end)
    :error_logger.info_report({:server2, m2})
    state = Map.put(state, :server, elem(m2, 1))
    {:noreply, state}
  end
  def handle_info({:tcp_closed, port}, state) do
    ret = TcpServer.Master.delete_child(state.master, state.port)
    {:noreply, state}
  end

  def handle_info({:tcp, port, "quit\r\n"}, state) do
    ret = TcpServer.Master.delete_child(state.master, state.port)
    {:noreply, state}
  end

  def handle_info({:tcp, port, s}, state) do
    :error_logger.info_report({:server2, s, port})
    {ret, b} = Code.eval_string(s)
    :error_logger.info_report({:server2, ret, state})
    ret = GenServer.call(state.server, {:factor, [ret]}, 300)
    :error_logger.info_report({:server, {s}, ret})
    :gen_tcp.send(port, :io_lib.format('~p\r\n', [ret]))
    {:noreply, state}
  end
  def handle_info({:tcp, port, message}, state) do
    :error_logger.info_report({:server, message})
    {ret, b} = Code.eval_string(message)
    :error_logger.info_report({:server, message, ret})
    :gen_tcp.send(port, :io_lib.format('~p\r\nn', [ret]))
    
    {:noreply, state}
  end
  def handle_info(a, state) do
    :error_logger.info_report({:server_other_info_ignore, a, state})
    {:noreply, state}
  end
  def terminate(reason, state) do
    :gen_tcp.send(state.port, "error\r\n")
    case elem(reason, 0) do
      :timeout ->
        :error_logger.info_report({:terminate, reason, 
                                   :erlang.is_pid(state.listener)})
        :ok = save_socket(state.port, state.listener)
        reason
      _ ->
        :error_logger.info_report({:terminate, reason, state})
        TcpServer.Master.delete_child(state.master, state.port)
    end
  end
end
