defmodule Broker.LoadBalancer do
  use GenServer
  require Logger

  def start_link(nr) do
    GenServer.start_link(__MODULE__, nr, name: __MODULE__)
  end

  def init(nr) do
    Logger.info("Load balancer #{inspect(self())} is up")
    nodes = for i <- 1..nr, into: %{}, do: {i, 0}
    {:ok, %{nr_nodes: nr, msg_nr: 0, nodes: nodes, avg: 0}}
  end

  def dispatch_msg(msg) do
    GenServer.cast(__MODULE__, {:dispatch, msg})
  end

  def handle_cast({:dispatch, msg}, state) do
    worker =
      rem(state[:msg_nr], state[:nr_nodes])
      |> Broker.Supervisor.get_process()

    Broker.Worker.handle(worker, msg)
    {:noreply, %{state | msg_nr: state[:msg_nr] + 1}}
  end
end
