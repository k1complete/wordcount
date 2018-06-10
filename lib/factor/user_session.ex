defmodule Factor.UserSession do
  use GenServer
  @spec start_link(term, term):: {:ok, pid} | no_return()
  def start_link({listener, port, parent, master, factor}, opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {listener, port, parent, master, factor}, opts)
    {:ok, pid}
  end
  def init({listener, port, parent, master, factor}) do
    #:error_logger.info_report({:us, {listener, port, parent, factor}})
    :ok = GenServer.cast(self(),
      {:setup, listener, self(), port, parent})
    {:ok, %{listener: listener, 
            port: port, 
            parent: parent, 
            master: master, 
            server: factor, 
            state: ""}}
  end
  @spec handle_cast(command :: tuple, state :: any) :: {:norelply, any}
  def handle_cast({:setup, listener, pid, port, parent}, state) do
    :ok = GenServer.call(listener, {:take_socket, port, pid})
    :ok = :inet.setopts(port, [active: :true, mode: :binary, packet: :line])
    m = Supervisor.which_children(parent)
    [m2] = Enum.filter(m, fn(e) -> elem(e, 0) == state.server end)
    state = Map.put(state, :server, elem(m2, 1))
    {:noreply, state}
  end
  @spec handle_info(command :: tuple, state :: any) :: {:norelply, any}
  def handle_info({:tcp_closed, port}, state) do
    :ok = TcpServer.Master.delete_child(state.master, port, state.listener)
    {:noreply, state}
  end
  def handle_info({:tcp, port, "quit\r\n"}, state) do
    :ok = TcpServer.Master.delete_child(state.master, port, state.listener)
    {:noreply, state}
  end
  def handle_info({:tcp, port, s}, state) do
    :error_logger.info_report({:server, s, port})
    {ret, _b} = Code.eval_string(s)
    ret = GenServer.call(state.server, {:factor, [ret]}, 300)
    #:error_logger.info_report({:server, {s}, ret})
    :gen_tcp.send(port, :io_lib.format('~p\r\n', [ret]))
    {:noreply, state}
  end
  @spec terminate(reason :: any, state :: any) :: any
  def terminate(reason, state) do
    :gen_tcp.send(state.port, "error\r\n")
    case elem(reason, 0) do
      :timeout ->
        :error_logger.info_report({:terminate, reason, 
                                   :erlang.is_pid(state.listener)})
        :ok = TcpServer.Listener.save_socket(state.port, state.listener)
        reason
      _ ->
        :error_logger.warning_report({:terminate, reason, state})
        TcpServer.Master.delete_child(state.master, state.port, state.listener)
    end
  end
end
