defmodule Ello.EventStream.Kinesis.ShardProcessorTest do
  use ExUnit.Case
  alias Ello.EventStream.{
    Kinesis.ShardProcessor,
    Event,
  }

  setup do
    Application.put_env(:ello_event_stream, :kinesis_client, __MODULE__)
    Application.put_env(:ello_event_stream, :kinesis_read_request_min_rate, 0)
    :ok
  end

  test "starting without a sequence number" do
    Process.register(self(), :test_process)

    task = Task.async(ShardProcessor, :process, [
      "ello-events",
      "test1",
      {__MODULE__, :callback},
      [limit: 2]
    ])
    assert_receive %Event{data: %{msg: 1}}
    assert_receive %Event{data: %{msg: 2}}
    assert_receive %Event{data: %{msg: 3}}
    assert_receive %Event{data: %{msg: 4}}
    Process.unregister(:test_process)
  end

  # Consumer interface
  def callback(event) do
    send(:test_process, event)
    :ok
  end

  # Kinises client interface
  def get_iterator("ello-events", "test1", nil), do: "test1-iterator1"
  def events("test1-iterator1", _limit) do 
    events = [
      %Event{type: "test", sequence_number: 1, data: %{msg: 1}},
      %Event{type: "test", sequence_number: 2, data: %{msg: 2}},
    ]
    {events, "test1-iterator2", 10}
  end
  def events("test1-iterator2", _limit) do 
    events = [
      %Event{type: "test", sequence_number: 3, data: %{msg: 3}},
      %Event{type: "test", sequence_number: 4, data: %{msg: 4}},
    ]
    {events, nil, 10}
  end

end
