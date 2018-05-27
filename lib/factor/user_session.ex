defmodule Factor.UserSession do
  use GenServer
  def start_link({listener, port, parent, master, factor}, opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {listener, port, parent, master, factor}, opts)
    {:ok, pid}
  end
  def init({listener, port, parent, master, factor}) do
    :ok = GenServer.cast(listener, {:accepted, self(), port, master, factor})
    {:ok, %{listener: listener, 
            port: port, 
            parent: parent, 
            master: master, 
            server: factor, 
            state: ""}}
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
    :error_logger.info_report({:server2, s})
    {ret, b} = Code.eval_string(s)
    :error_logger.info_report({:server2, ret})
    ret = GenServer.call(state.server, {:factor, [ret]})
    :error_logger.info_report({:server, {s}, ret})
    :gen_tcp.send(port, :io_lib.format('~p~n', [ret]))
    {:noreply, state}
  end
  def handle_info({:tcp, port, message}, state) do
    :error_logger.info_report({:server, message})
    {ret, b} = Code.eval_string(message)
    :error_logger.info_report({:server, message, ret})
    :gen_tcp.send(port, :io_lib.format('~p~n', [ret]))
    
    {:noreply, state}
  end
  def handle_info(a, state) do
    :error_logger.info_report({:server_other_info_ignore, a, state})
    {:noreply, state}
  end
  def terminate(reason, state) do
    :error_logger.info_report({:terminate, reason, state})
    TcpServer.Master.delete_child(state.master, state.port)
    reason
  end
end
