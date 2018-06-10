defmodule Factor do
  use Application
  def start() do
    :ok = :application.start(:factor)
  end
  def start(_type, _args) do
    ret = TcpServer.Master.start_link(:factor_sup, 
      %{listener: :factor_listener})
    ret
  end
  def stop() do
    :application.stop(:factor)
  end
end
