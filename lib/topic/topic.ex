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

    Logger.debug(inspect(msg))

    {:noreply, state}
  end

end
