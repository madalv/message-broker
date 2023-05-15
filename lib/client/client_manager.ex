defmodule Client.Manager do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Client Manager is up")
    {:ok, %{cnt: 1}}
  end

  def dispatch(id, msg) do
    client_pid =
      if is_atom(id) do
        id |> Client.Supervisor.get_process()
      else
        id |> to_string() |> String.to_atom() |> Client.Supervisor.get_process()
      end

    Client.handle_msg(client_pid, msg)
  end

  def handle_sub(id, from) do
    GenServer.call(__MODULE__, {:conn, id, from})
  end

  def handle_call({:conn, id, from}, _from, state) do
    if id == 0 do
      new_id = state[:cnt] |> to_string() |> String.to_atom()
      Client.Supervisor.add_client(new_id, from)
      dispatch(new_id, "Your ID is #{new_id}")
      {:reply, new_id, %{state | cnt: state[:cnt] + 1}}
    else
      new_id = id |> to_string() |> String.to_atom()

      if !Client.Supervisor.client_exists?(new_id) do
        Client.Supervisor.add_client(new_id, from)
      end

      {:reply, new_id, %{state | cnt: id + 1}}
    end
  end
end
