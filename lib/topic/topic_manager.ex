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

  def dispatch(msg, from) do
    GenServer.cast(__MODULE__, {:dispatch, msg, from})
  end

  def handle_cast({:dispatch, msg_json, from}, list) do
    msg = decode(msg_json, from)

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

  defp decode(msg, from) do
    decoded = Jason.decode(msg)

    case decoded do
      {:ok, %{"event" => "sub", "data" => id, "topics" => topics}} ->
        new_id = Client.Manager.handle_sub(id, from)
        %{"event" => "sub", "data" => new_id, "topics" => topics}

      {:ok, %{"event" => "ack", "data" => [id, msg], "topics" => _topics}} ->
        Client.Manager.dispatch(id, {"ack", msg})
        %{"event" => "ack", "data" => {id, msg}, "topics" => []}

      {:ok, m = %{"event" => _, "data" => _data, "topics" => _topics}} ->
        m

      unsendable ->
        Topic.DeadLtrChannel.handle_unsendable(unsendable)
        %{"event" => "unsendable_msg", "data" => unsendable, "topics" => []}
    end
  end
end
