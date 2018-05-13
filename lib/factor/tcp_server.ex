defmodule Factor.TcpServer do
  use GenServer
  def start_link({listener, port, parent, master, factor}, opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {listener, port, parent, master, factor}, opts)
    {:ok, pid}
  end
  def init({listener, port, parent, master, factor}) do
    :ok = GenServer.cast(listener, {:accepted, self(), port, master, factor})
    {:ok, {listener, port, parent, master, factor}}
  end
  def handle_info({:tcp_closed, port}, state = {listener, lport, parent, master, factor}) do
    ret = Factor.Master.delete_child(master, port)
    {:noreply, state}
  end
  def handle_info({:tcp, port, 'quit\r\n'}, state = {listener, lport, parent, master, factor}) do
    ret = Factor.Master.delete_child(master, port)
    {:noreply, state}
  end

  def handle_info({:tcp, port, s}, state = {listener, lport, parent, master, factor}) do
    :error_logger.info_report({:server, s})
    {ret, b} = Code.eval_string(s)
    :error_logger.info_report({:server2, ret})
    ret = GenServer.call(factor, {:factor, [ret]})
    :error_logger.info_report({:server, s, ret})
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
  def terminate(reason, state = {listener, lport, parent, master, factor}) do
    :error_logger.info_report({:terminate, reason, state})
    Factor.Master.delete_child(master, lport)
    reason
  end
end
