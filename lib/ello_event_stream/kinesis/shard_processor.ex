defmodule Ello.EventStream.Kinesis.ShardProcessor do
  require Logger
  alias Ello.EventStream.{
    Kinesis,
  }

  defmodule State do
    defstruct [
      stream:     nil,
      shard:      nil,
      iterator:   nil,
      callback:   nil,
      limit:      100,
      events:     [],
      last_fetch: nil,
      exit:       false,
      last_sequence_number: nil,
    ]
  end

  def process(stream, shard, callback, opts) do
    process(%State{
      stream:   stream,
      shard:    shard,
      callback: callback,
      limit:    opts[:limit] || 100,
    })
  end

  def process(%State{exit: true, shard: shard}) do
    Logger.info("Shard #{shard} has been closed, all records are processed")
    Process.exit(self(), :normal)
  end

  def process(%State{} = state) do
    state
    |> get_last_sequence_number
    |> get_new_iterator
    |> rate_limit
    |> get_events
    |> process_events
    |> process
  end

  defp get_last_sequence_number(%{last_sequence_number: nil} = state) do
    #TODO: Get from redis
    state
  end
  defp get_last_sequence_number(state), do: state

  defp get_new_iterator(%{iterator: nil} = state) do
    case kinesis().get_iterator(state.stream, state.shard, state.last_sequence_number) do
      nil   -> %{state | iterator: nil, exit: true}
      other -> %{state | iterator: other}
    end
  end
  defp get_new_iterator(state), do: state

  defp rate_limit(%{last_fetch: nil} = state),
    do: %{state | last_fetch: System.system_time(:second)}
  defp rate_limit(%{last_fetch: last_fetch} = state) do
    if (last_fetch - System.system_time(:second)) < 1 do
      :timer.sleep(1000)
    end
    %{state | last_fetch: System.system_time(:second)}
  end

  defp get_events(%{exit: true} = state), do: state
  defp get_events(state) do
    case kinesis().events(state.iterator, state.limit) do
      {:error, :iterator_expired} ->
        %{state | events: [], interator: nil}
      {events, nil, _ms_behind} ->
        %{state | events: events, iterator: nil, exit: true}
      {events, next_iterator, ms_behind} ->
        Logger.info "Got batch of #{length(events)} records, #{ms_behind}ms behind latest"
        %{state | events: events, iterator: next_iterator}
    end
  end

  defp process_events(%{exit: true} = state), do: state
  defp process_events(%{events: []} = state), do: state
  defp process_events(%{events: [event | rest]} = state) do
    Logger.debug "Processing #{event.type} event ##{event.sequence_number}."
    {mod, fun} = state.callback
    case apply(mod, fun, [event]) do
      :ok ->
        state
        |> set_last_sequence_number(event)
        |> Map.put(:events, rest)
        |> process_events
      _ -> raise "Processing failed"
    end
  end

  defp set_last_sequence_number(state, %{sequence_number: sequence_number}) do
    #TODO: Put in redis.
    %{state | last_sequence_number: sequence_number}
  end

  def kinesis do
    Application.get_env(:ello_event_stream, :kinesis, Kinesis)
  end
end
