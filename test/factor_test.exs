defmodule FactorTest do
  use ExUnit.Case
  doctest Factor.Server
  setup_all do
    Factor.start(:a, :b)
#    on_exit fn ->
#      Factor.stop()
#    end
    :ok
  end
  test "sever()" do
    a= GenServer.call(:sup_factor, :new)
    {:factor, [6]} == [3,2]
  end
    

end
