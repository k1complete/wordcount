defmodule Factor do
  use Application
  def start() do
    :ok = :application.start(:factor)
  end
  def start(_type, _args) do
    ret = TcpServer.Master.start_link(:factor_sup, 
      %{supervisor: :factor_sup})
    ret
  end
  def stop() do
    :application.stop(:factor)
  end
  def stop(state) do
    TcpServer.Master.stop(:application_stop, state)
  end
end
