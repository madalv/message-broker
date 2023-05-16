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
    new_clients =
      case msg do
        {"sub", id} ->
          if id in state[:clients] do
            state[:clients]
          else
            [id | state[:clients]]
          end

        {"unsub", id} ->
          string_id = id |> to_string() |> String.to_atom()
          state[:clients] -- [string_id]

        {"msg", data} ->
          for client <- state[:clients],
              do: Client.Manager.dispatch(client, data)

          state[:clients]

        {"unsendable", _data} ->
          nil
          state[:clients]
      end

    Logger.debug("TOPIC old #{state[:name]} #{inspect(state[:clients])}")
    Logger.debug("TOPIC #{state[:name]} #{inspect(new_clients)}")

    {:noreply, %{state | clients: new_clients}}
  end
end
