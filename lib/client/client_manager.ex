defmodule Client.Manager do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Client Manager is up")
    :dets.open_file(:clients, [{:type, :set}])
    {:ok, %{cnt: 1}}
  end


  def get_pid(id) do
    if is_atom(id) do
        id |> Client.Supervisor.get_process()
      else
        id |> to_string() |> String.to_atom() |> Client.Supervisor.get_process()
      end
  end

  def dispatch(id, msg) do
    client_pid = get_pid(id)
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
      else
        pid = get_pid(id)
        Client.change_socket(pid, from)
      end

      new_cnt = if id < state[:cnt] do state[:cnt] + 1 else id + 1 end
      {:reply, new_id, %{state | cnt: new_cnt}}
    end
  end
end
