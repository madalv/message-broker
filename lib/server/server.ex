defmodule Server do
  require Logger

  def init({ip, port}) do
    Process.flag(:trap_exit, true)
    pid =
      spawn_link(fn ->
        {:ok, listen_socket} =
          :gen_tcp.listen(port, [:binary, {:packet, :line}, {:active, true}, {:ip, ip}])

        Logger.info("TCP Server #{inspect(self())} accepting connections on port #{port}")

        accept(listen_socket, {ip, port})
      end)

    {:ok, pid}
  end

  defp accept(listen_socket, {ip, port}) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client} ->
        pid =
          spawn_link(fn ->
            Logger.info("Connection accepted on P#{port}: #{inspect(client)}")

            loop({ip, port})
          end)

        # set the controlling process of the client socket to the spawn
        :gen_tcp.controlling_process(client, pid)
        accept(listen_socket, {ip, port})

      err ->
        Logger.error(err)
    end
  end

  def loop({ip, port}) do
    receive do
      {:tcp, socket, packet} ->
        Logger.info("INCOMING P#{port}: #{inspect(packet)}")
        # :gen_tcp.send(socket, "Hello World \n")
        Broker.LoadBalancer.dispatch_msg(packet)
        loop({ip, port})

      {:tcp_closed, socket} ->
        Logger.info("CLOSED P#{port}: #{inspect(socket)}")

      {:tcp_error, socket, reason} ->
        Logger.info("Error P#{port} #{reason} #{inspect(socket)}")
    end
  end
end
