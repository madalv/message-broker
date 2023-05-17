defmodule Server do
  require Logger

  def init({ip, port}) do
    Process.flag(:trap_exit, true)

    pid =
      spawn_link(fn ->
        {:ok, listen_socket} =
          :gen_tcp.listen(port, [:binary, {:packet, :line}, {:active, true}, {:ip, ip}])

        Logger.info("TCP Server #{inspect(self())} accepting connections on port #{port} IP#{inspect(ip)}")

        accept(listen_socket, {ip, port})
      end)

    {:ok, pid}
  end

  defp accept(listen_socket, {ip, port}) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client} ->
        pid =
          spawn_link(fn ->
            Logger.info("Connection accepted on P#{port} : #{inspect(client)}")

            loop({ip, port})
          end)

        # set the controlling process of the client socket to the spawn
        :gen_tcp.controlling_process(client, pid)
        accept(listen_socket, {ip, port})

      err ->
        Logger.error(err)
    end
  end

  defp loop({ip, port}) do
    receive do
      {:tcp, socket, packet} ->
        Topic.Manager.dispatch(packet, socket)
        loop({ip, port})

      {:tcp_closed, socket} ->
        Logger.info("CLOSED P#{port}: #{inspect(socket)}")

      {:tcp_error, socket, reason} ->
        Logger.info("Error P#{port} #{reason} #{inspect(socket)}")
    end
  end
end
