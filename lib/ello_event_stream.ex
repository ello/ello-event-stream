defmodule Ello.EventStream do
  alias __MODULE__.{
    Event,
    Kinesis.StreamSupervisor
  }

  def read(stream, callback, opts \\ %{}) do
    StreamSupervisor.start_stream(stream, callback, opts)
  end

  # Ello.EventStream.tmp
  def tmp do
    read("ello-staging-stream", {__MODULE__, :inspect})
  end

  def inspect(event) do
    event
    |> IO.inspect
    :ok
  end
end
