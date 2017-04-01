defmodule Ello.EventStream.Kinesis.StreamSupervisor do
  @moduledoc """
  For each stream, starts and supervises each shard to be read.
  """
  use Supervisor
  alias Ello.EventStream.{
    Kinesis,
    Kinesis.ShardProcessor,
  }

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Starts processing a stream.

  Gets each shard from the stream and starts a ShardSupervisor for each one.
  """
  def start_stream(stream, callback, opts) do
    stream
    |> Kinesis.shard_ids
    |> Enum.map(&Supervisor.start_child(__MODULE__, [ShardProcessor, :process, [stream, &1, callback, opts]]))
  end

  def init(:ok) do
    children = [worker(Task, [], restart: :transient)]
    supervise(children, strategy: :simple_one_for_one)
  end
end
