defmodule FactorTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Logger

  doctest Factor.Server
  setup  do
    {:ok, pid} = Factor.Server.start({})
    on_exit(fn() ->
      IO.inspect [exit: pid]
      case Process.alive?(pid) do
        true ->
          Factor.Server.stop(pid)
        false ->
          :ok
      end
    end)
    [pid: pid]
  end
  test "tcp connect", _context do
    {:ok, s} = :gen_tcp.connect(:localhost, 30000, [{:active, :false}, {:packet, :line}])
    :ok = :gen_tcp.send(s, "100\r\n")
    {:ok, res} = :gen_tcp.recv(s, 0)
    assert '[5,5,2,2]\r\n' == res
    :ok = :gen_tcp.send(s, "100000001\r\n")
    {:ok, res} = :gen_tcp.recv(s, 0)
    assert 'error\r\n' == res
    :ok = :gen_tcp.send(s, "quit\r\n")
    res = :gen_tcp.recv(s, 0)
    assert {:error, :closed} == res
  end
  test "tcp connect parse error", _context do
    {:ok, s} = :gen_tcp.connect(:localhost, 30000, [{:active, :false}, {:packet, :line}])
    :ok = :gen_tcp.send(s, "a\r\n")
    {:ok, res} = :gen_tcp.recv(s, 0)
    assert 'error\r\n' == res
    res = :gen_tcp.recv(s, 0)
    assert {:error, :closed} == res
  end
  test "tcp connect closed", _context do
    {:ok, s} = :gen_tcp.connect(:localhost, 30000, [{:active, :false}, {:packet, :line}])
    :ok = :gen_tcp.send(s, "2\r\n")
    {:ok, res} = :gen_tcp.recv(s, 0)
    assert '[2]\r\n' == res
    res = :gen_tcp.close(s)
    assert :ok == res
  end
  test "tcp connect killed", _context do
    {:ok, s} = :gen_tcp.connect(:localhost, 30000, [{:active, :false}, {:packet, :line}])
    :ok = :gen_tcp.send(s, "2\r\n")
    {:ok, res} = :gen_tcp.recv(s, 0)
    assert '[2]\r\n' == res
    res = :gen_tcp.close(s)
    assert :ok == res
  end
  test "sever(6)", context do
    a = GenServer.call(context.pid, {:factor, [6]})
    assert a == [3, 2]
  end
  test "sever(31)", context do
    a = GenServer.call(context.pid, {:factor, [31]})
    assert a == [31]
  end
  test "sever(:a)", context do
    assert capture_log(fn() ->
      catch_exit(:error=GenServer.call(context.pid, {:factor, [:a]}))
    end)  =~ "(ArithmeticError)"
  end
  

end
