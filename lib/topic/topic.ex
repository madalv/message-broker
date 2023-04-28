defmodule Topic do
  use GenServer
  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def init(name) do
    Logger.info("Topic #{name} is up")
    {:ok, %{name: name, clients: []}}
  end

  def handle(pid, msg) do
    GenServer.cast(pid, {:handle, msg})
  end

  def handle_cast({:handle, msg}, state) do
    # todo: error handling
    new_clients =
      case msg do
        {"sub", id} ->
          [id | state[:clients]]

        {"unsub", id} ->
          state[:clients] -- [id]

        {"msg", data} ->
          for client <- state[:clients],
              do: Client.Manager.dispatch(client, data)

        {"unsendable", _data} ->
          nil
          state[:clients]
      end

    Logger.debug("TOPIC #{state[:name]} #{inspect(new_clients)}")

    {:noreply, %{state | clients: new_clients}}
  end
end
