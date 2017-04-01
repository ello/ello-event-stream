defmodule Ello.EventStream.Kinesis.ShardProcessor do
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
      events:    [],
      last_fetch: nil,
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
    %{state | iterator: Kinesis.get_iterator(state.stream, state.shard, state.last_sequence_number)}
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

  defp get_events(state) do
    {events, next_iterator} = Kinesis.events(state.iterator, state.limit)
    %{state | events: events, iterator: next_iterator}
  end

  defp process_events(%{events: []} = state), do: state
  defp process_events(%{events: [next | rest]} = state) do
    {mod, fun} = state.callback
    case apply(mod, fun, [next]) do
      :ok ->
        state
        |> set_last_sequence_number(next)
        |> Map.put(:events, rest)
        |> process_events
      _ -> raise "Processing failed"
    end
  end

  defp set_last_sequence_number(state, %{sequence_number: sequence_number}) do
    #TODO: Put in redis.
    %{state | last_sequence_number: sequence_number}
  end
end
