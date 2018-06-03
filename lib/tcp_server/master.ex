defmodule TcpServer.Master do
  use Supervisor
  import Supervisor.Spec
  def start_link(name, arg) do
    arg = Map.put(arg, :name, name)
    ret = Supervisor.start_link(__MODULE__, arg, [name: name])
    ret
  end
  def init(%{supervisor: sup, name: name}) do
    {:ok, {{:one_for_one,
            10,
            100},
           [
             worker(TcpServer.Listener, 
               [%{accepter: &__MODULE__.accepted/2,
                 supervisor: name}, 
                [name: :factor_listener]], 
               [id: :factor_listener])
    ]}}
  end
  def accepted(super_ref, port) do
    child = supervisor(TcpServer.Supervisor, 
      [{:factor_listener, port, super_ref}], 
      [id: port])
    {:ok, cid} = Supervisor.start_child(super_ref, child)
    :ok = TcpServer.Supervisor.start_child({:factor_listener, 
                                            port, cid, super_ref})
  end
  def accept(super_ref) do
    GenServer.cast(:factor_listener, {:accept, super_ref, &TcpServer.Master.accepted/2})
  end
  def connect(super_ref, key) do
    child = supervisor(TcpServer.Supervisor, [[], [name: key]], [id: key])
    Supervisor.start_child(super_ref, child)
  end
  def delete_child(super_ref, child) do
    Supervisor.terminate_child(super_ref, child)
    Supervisor.delete_child(super_ref, child)
  end
  def stop(term, state) do
    a = Supervisor.stop(term, state)
    IO.inspect [stop: a]
    a
  end
  
end
