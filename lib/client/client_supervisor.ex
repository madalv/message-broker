defmodule Client.Supervisor do
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)

    children = []

    Client.Manager.start_link()

    Supervisor.init(children, strategy: :one_for_one)
  end

  def add_client(name, socket) when is_atom(name) do
    Supervisor.start_child(__MODULE__, %{
      id: name,
      start: {Client, :start_link, [{name, socket}]}
    })

    Logger.debug("Added new client #{name} #{inspect(Supervisor.which_children(__MODULE__))}")
    # get_process(name)
  end

  def client_exists?(name) when is_atom(name) do
    Enum.any?(
      Supervisor.which_children(__MODULE__),
      fn {id, _, _, _} -> id == name end
    )
  end

  def get_process(name) when is_atom(name) do
    Supervisor.which_children(__MODULE__)
    |> Enum.find(fn {id, _, _, _} -> id == name end)
    |> elem(1)
  end

  def get_process(int) when is_integer(int) do
    Supervisor.which_children(__MODULE__)
    |> Enum.at(int)
    |> elem(1)
  end
end
