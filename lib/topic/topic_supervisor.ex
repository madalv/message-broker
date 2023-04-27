defmodule Topic.Supervisor do
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)

    children = [%{id: :cat, start: {Topic, :start_link, [:cat]}}]

    Topic.Manager.start_link()

    Supervisor.init(children, strategy: :one_for_one)
  end

  def add_topic(name) when is_atom(name) do

    Supervisor.start_child(__MODULE__, %{
      id: name,
      start: {Topic, :start_link, [name]}
    })

    Logger.debug("Added new child #{name} #{inspect(Supervisor.which_children(__MODULE__))}")
    get_process(name)
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
