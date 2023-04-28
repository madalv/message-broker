defmodule Client do
  use GenServer
  require Logger

  def start_link({id, socket}) do
    GenServer.start_link(__MODULE__, {id, socket})
  end

  def init({id, socket}) do
    Logger.info("Client #{id} is up")
    {:ok, %{id: id, socket: socket, queue: [], ack_last: true}}
  end

  def handle_msg(pid, msg) do
    GenServer.cast(pid, {:handle, msg})
  end

  def handle_cast({:handle, msg}, state) do
    :gen_tcp.send(state[:socket], msg <> "\n")
    {:noreply, state}
  end
end
