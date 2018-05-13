defmodule Factor do
  use Application
  def start() do
    :ok = :application.start(:factor)
  end
  def start(_type, _args) do
    ret = Factor.Master.start_link(:factor_sup, [])
    Factor.Master.accept(:factor_sup)
    ret
  end
  def stop() do
    :application.stop(:factor)
  end
  def stop(state) do
    Factor.Master.stop(:application_stop, state)
  end
end
