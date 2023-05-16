defmodule Topic.DeadLtrChannel do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Dead Letter Channel is up.")
    {:ok, []}
  end

  def handle_unsendable(msg) do
    GenServer.cast(__MODULE__, {:handle, msg})
  end

  def handle_cast({:handle, msg}, state) do
    new = [msg | state]
    Logger.info("Dead Letter Channel state: #{inspect(new)}")
    {:noreply, new}
  end
end
