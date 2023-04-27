defmodule Broker.Worker do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle(pid, msg) do
    GenServer.cast(pid, {:handle, msg})
  end

  def handle_cast({:handle, msg}, state) do
    decoded = Jason.decode!(msg)

    case decoded do
      %{"event" => "msg", "data" => _data, "topics" => _topics} ->
        Logger.debug(inspect(decoded))

      %{"event" => "sub", "data" => _, "topics" => _topics} ->
        Logger.info("SUB MSG")

      %{"event" => "unsub", "data" => _, "topics" => _topics} ->
        Logger.info("UNSUB MSG")
    end

    {:noreply, state}
  end
end
