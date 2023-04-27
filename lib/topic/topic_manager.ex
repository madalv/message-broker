defmodule Topic.Manager do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [:cat], name: __MODULE__)
  end

  def init(list) do
    Logger.info("Topic Manager is up")
    {:ok, list}
  end

  def dispatch(msg) do
    GenServer.cast(__MODULE__, {:dispatch, msg})
  end

  def handle_cast({:dispatch, msg_json}, list) do
    msg = decode(msg_json)

    Logger.debug(inspect(list))

    new_topic_list =
      Enum.reduce(msg["topics"], list, fn string, acc ->
        topic = string |> String.downcase() |> String.to_atom()

        if topic in list do
          topic_pid = Topic.Supervisor.get_process(topic)
          Topic.handle(topic_pid, {msg["event"], msg["data"]})
          acc
        else
          new_topic_pid = Topic.Supervisor.add_topic(topic)
          Topic.handle(new_topic_pid, {msg["event"], msg["data"]})
          [topic | acc]
        end
      end)

    {:noreply, new_topic_list}
  end

  defp decode(msg) do
    decoded = Jason.decode(msg)

    case decoded do
      {:ok, m = %{"event" => _, "data" => _data, "topics" => _topics}} ->
        m

      unsendable ->
        %{"event" => "unsendable_msg", "data" => unsendable, "topics" => ["dead_letter_channel"]}
    end
  end
end
