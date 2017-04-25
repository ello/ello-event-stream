defmodule Ello.EventStream.Kinesis do

  alias Ello.EventStream.{
    Event,
  }

  @doc """
  Get the shard ids for a given stream.
  """
  def shard_ids(stream) do
    with {:ok, resp} <- describe_stream(stream),
         shards when is_list(shards) <- resp["StreamDescription"]["Shards"] do
      Enum.map(shards, &(&1["ShardId"]))
    else
      _ -> raise "Stream #{stream} not found"
    end
  end

  @doc """
  Get an interator for the shard and known sequence_number.
  """
  def get_iterator(stream, shard, nil) do
    req = client().get_shard_iterator(stream, shard, :trim_horizon)
    {:ok, resp} = client_execute(req)
    resp["ShardIterator"]
  end
  def get_iterator(stream, shard, sequence_number) do
    req = client().get_shard_iterator(stream, shard, :after_sequence_number,
                                      starting_sequence_number: sequence_number)
    {:ok, resp} = client_execute(req)
    resp["ShardIterator"]
  end

  @doc """
  Retrieves events starting at the given iterator.
  """
  def events(iterator, limit, backoff \\ 1000) do
    req = client().get_records(iterator, limit: limit)
    case client_execute(req) do
      {:ok, %{"Records" => records, "NextShardIterator" => next, "MillisBehindLatest" => ms_behind}} ->
        {Enum.map(records, &Event.from_kinesis/1), next, ms_behind}
      {:error, {:http_error, 400, %{"__type" => "ExpiredIteratorException"}}} ->
        {:error, :iterator_expired}
      {:error, _} ->
        :timer.sleep(backoff)
        events(iterator, limit, backoff * 2)
    end
  end

  defp describe_stream(stream) do
    client_execute(client().describe_stream(stream))
  end

  defp client do
    Application.get_env(:ello_event_stream, :client, ExAws.Kinesis)
  end

  defp client_execute(request) do
    {mod, fun} = Application.get_env(:ello_event_stream, :client_execute, {ExAws, :request})
    apply(mod, fun, [request])
  end
end
