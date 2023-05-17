defmodule Client do
  use GenServer
  require Logger

  def start_link({id, socket}) do
    GenServer.start_link(__MODULE__, {id, socket})
  end

  def init({id, socket}) do
    Logger.info("Client #{id} is up")
    :timer.send_after(5000, self(), :send)

    string_id = id |> to_string() |> String.to_atom()

    persisted =
      case :dets.lookup(:clients, string_id) do
        [{_, data}] -> data
        [] -> []
      end

    Logger.debug("Client #{id}'s persisted queue: #{inspect(persisted)}")
    {:ok, %{id: id, socket: socket, queue: persisted, last_ack: true, retry_lim: 10}}
  end

  def change_socket(pid, socket) do
    GenServer.cast(pid, {:socket, socket})
  end

  def handle_cast({:socket, socket}, state) do
    {:noreply, %{state | socket: socket, retry_lim: 10}}
  end

  def handle_msg(pid, msg) do
    case msg do
      {"ack", msg} ->
        GenServer.cast(pid, {:ack, msg})

      _ ->
        GenServer.cast(pid, {:handle, msg})
    end
  end

  def handle_cast({:ack, msg_ack}, state) do
    [msg | tail] = state[:queue]
    string_id = state[:id] |> to_string() |> String.to_atom()

    if msg == msg_ack and !state[:last_ack] do
      Logger.debug("Client #{state[:id]}. Ack came for #{msg}. Queue: #{inspect(tail)}")
      :dets.insert(:clients, {string_id, tail})
      {:noreply, %{state | last_ack: true, retry_lim: 10, queue: tail}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:handle, msg}, state) do
    queue = state[:queue] ++ [msg]
    string_id = state[:id] |> to_string() |> String.to_atom()
    :dets.insert(:clients, {string_id, queue})
    {:noreply, %{state | queue: queue}}
  end

  def handle_info(:send, state) do
    :timer.send_after(5000, self(), :send)

    if length(state[:queue]) > 0 do
      [msg | _tail] = state[:queue]

      Logger.debug(
        "Client #{state[:id]}. Msg: #{msg}. Queue: #{inspect(state[:queue])}. Last ack? #{state[:last_ack]}. Retry: #{state[:retry_lim]}."
      )

      cond do
        state[:last_ack] ->
          :gen_tcp.send(state[:socket], msg <> "\n")
          {:noreply, %{state | last_ack: false}}

        !state[:last_ack] and state[:retry_lim] > 0 ->
          :gen_tcp.send(state[:socket], msg <> "\n")
          cnt = state[:retry_lim] - 1
          {:noreply, %{state | retry_lim: cnt}}

        true ->
          Logger.debug("Client #{state[:id]} assumed dead.")
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
end
