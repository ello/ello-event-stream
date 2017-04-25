defmodule Ello.EventStream.KinesisTest do
  use ExUnit.Case, aync: false
  alias Ello.EventStream.{
    Kinesis,
    Event
  }

  setup do
    Application.put_env(:ello_event_stream, :client_execute, {__MODULE__, :client_execute})
    on_exit fn ->
      Application.delete_env(:ello_event_stream, :client_execute)
    end
    :ok
  end

  test "getting shard ids" do
    assert ["shardId-000000000001", "shardId-000000000002"] ==
      Kinesis.shard_ids("ello-test-stream")
  end

  test "get iterator - no sequence number" do
    assert "AAAAAAAAAfoo==" ==
      Kinesis.get_iterator("ello-staging-stream", "shardId-000000000001", nil)
  end

  test "get iterator - with sequence number" do
    assert "AAAAAAAAAbar==" ==
      Kinesis.get_iterator("ello-staging-stream", "shardId-000000000001", "abc")
  end

  test "get events - expired iterator" do
    assert {:error, :iterator_expired} = Kinesis.events("AAAAAAAAAexp==", 2)
  end

  test "get events" do
    assert {events, next, ms_behind} = Kinesis.events("AAAAAAAAApwv==", 2)
    assert next == "AAAAAAAAAAnext=="
    assert ms_behind == 85915000
    assert [%Event{} = e1, %Event{} = e2] = events
    assert e1.type == "post_was_viewed"
    assert e2.type == "post_was_viewed"
    assert is_map(e1.data)
    assert is_map(e2.data)
  end

  # Get Shard IDs - Example response (minus some fields)
  def client_execute(%{data: %{"StreamName" => "ello-test-stream"}}) do
    {:ok, %{
      "StreamDescription" => %{
        "Shards" => [%{
          "ShardId" => "shardId-000000000001"
        }, %{
          "ShardId" => "shardId-000000000002"
        }],
      }
    }}
  end

  # Get Iterator - no sequence number
  def client_execute(%{data: %{"ShardId" => "shardId-000000000001", "ShardIteratorType" => "TRIM_HORIZON"}}) do
    {:ok, %{"ShardIterator" => "AAAAAAAAAfoo=="}}
  end

  # Get Iterator - with sequence
  def client_execute(%{data: %{"ShardId" => "shardId-000000000001", "ShardIteratorType" => "AFTER_SEQUENCE_NUMBER"}}) do
    {:ok, %{"ShardIterator" => "AAAAAAAAAbar=="}}
  end

  # Get Events - iterator expired
  def client_execute(%{data: %{"Limit" => 2, "ShardIterator" => "AAAAAAAAAexp=="}}) do
    {:error, {:http_error, 400, %{
      "__type" => "ExpiredIteratorException",
      "message" => "Iterator expired. _"
    }}}
  end

  # Get Events - 2 post view events
  def client_execute(%{data: %{"Limit" => 2, "ShardIterator" => "AAAAAAAAApwv=="}}) do
    {:ok, %{
      "MillisBehindLatest" => 85915000,
      "NextShardIterator" => "AAAAAAAAAAnext==",
      "Records" => [
        %{
          "ApproximateArrivalTimestamp" => 1492264135.157,
          "Data" => "T2JqAQQUYXZyby5jb2RlYwhudWxsFmF2cm8uc2NoZW1h2gt7InR5cGUiOiJyZWNvcmQiLCJuYW1lIjoicG9zdF93YXNfdmlld2VkIiwiZmllbGRzIjpbeyJuYW1lIjoidXVpZCIsInR5cGUiOlsibnVsbCIsInN0cmluZyJdfSx7Im5hbWUiOiJwb3N0IiwidHlwZSI6eyJ0eXBlIjoicmVjb3JkIiwibmFtZSI6InBvc3QiLCJmaWVsZHMiOlt7Im5hbWUiOiJpZCIsInR5cGUiOiJzdHJpbmcifSx7Im5hbWUiOiJjcmVhdGVkX2F0IiwidHlwZSI6ImRvdWJsZSJ9LHsibmFtZSI6ImJvZHkiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoibnNmdyIsInR5cGUiOiJib29sZWFuIn0seyJuYW1lIjoidXJsIiwidHlwZSI6InN0cmluZyJ9XX19LHsibmFtZSI6ImF1dGhvciIsInR5cGUiOnsidHlwZSI6InJlY29yZCIsIm5hbWUiOiJ1c2VyIiwiZmllbGRzIjpbeyJuYW1lIjoiaWQiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoidXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoidXJsIiwidHlwZSI6InN0cmluZyJ9LHsibmFtZSI6ImlzX3ByaXZhdGUiLCJ0eXBlIjpbIm51bGwiLCJib29sZWFuIl19XX19LHsibmFtZSI6InZpZXdlciIsInR5cGUiOlsibnVsbCIsInVzZXIiXX0seyJuYW1lIjoidmlld2VkX2F0IiwidHlwZSI6ImRvdWJsZSJ9LHsibmFtZSI6ImZyb21fcmVwb3N0IiwidHlwZSI6ImJvb2xlYW4ifSx7Im5hbWUiOiJzdHJlYW1fa2luZCIsInR5cGUiOlsibnVsbCIsInN0cmluZyJdfSx7Im5hbWUiOiJzdHJlYW1faWQiLCJ0eXBlIjpbIm51bGwiLCJzdHJpbmciXX1dfQC0aNPI5Lj8O3TYtBrs/JLNArAGAkhkMTY3MDRiNi03MWRjLTQ2YTctYTk3OC1lMzZiNWU3ZjlmOTkMMTg0NDM0JQa5mqwy1kGQA1t7ImtpbmQiOiJpbWFnZSIsImRhdGEiOnsidXJsIjoiaHR0cHM6Ly9hc3NldHMyLmVsbG8ubmluamEvdXBsb2Fkcy9hc3NldC9hdHRhY2htZW50LzY4OTA3L2VsbG8tb3B0aW1pemVkLTc1NmIxMzczLmpwZyIsImFsdCI6IldvcmQgLSA2NjYgfCBlbGxvIiwiYXNzZXRfaWQiOjY4OTA3fX0seyJraW5kIjoidGV4dCIsImRhdGEiOiJXb3JkIEBzZWFuIn1dAGRodHRwczovL2VsbG8ubmluamEvNjY2L3Bvc3QvczVybWVobHBfcTltdzlta3B3NWFhYQI5BjY2NixodHRwczovL2VsbG8ubmluamEvNjY2AgACCDIzNzAWYWxhbnBlYWJvZHk8aHR0cHM6Ly9lbGxvLm5pbmphL2FsYW5wZWFib2R5AgAtsgUxiTzWQQECDHJlY2VudAIAtGjTyOS4/Dt02LQa7PySzQ==",
          "PartitionKey" => "d16704b6-71dc-46a7-a978-e36b5e7f9f99-post_was_viewed",
          "SequenceNumber" => "49571180486878550058857500677833309367236900860809183250"},
        %{
          "ApproximateArrivalTimestamp" => 1492264135.218,
          "Data" => "T2JqAQQUYXZyby5jb2RlYwhudWxsFmF2cm8uc2NoZW1h2gt7InR5cGUiOiJyZWNvcmQiLCJuYW1lIjoicG9zdF93YXNfdmlld2VkIiwiZmllbGRzIjpbeyJuYW1lIjoidXVpZCIsInR5cGUiOlsibnVsbCIsInN0cmluZyJdfSx7Im5hbWUiOiJwb3N0IiwidHlwZSI6eyJ0eXBlIjoicmVjb3JkIiwibmFtZSI6InBvc3QiLCJmaWVsZHMiOlt7Im5hbWUiOiJpZCIsInR5cGUiOiJzdHJpbmcifSx7Im5hbWUiOiJjcmVhdGVkX2F0IiwidHlwZSI6ImRvdWJsZSJ9LHsibmFtZSI6ImJvZHkiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoibnNmdyIsInR5cGUiOiJib29sZWFuIn0seyJuYW1lIjoidXJsIiwidHlwZSI6InN0cmluZyJ9XX19LHsibmFtZSI6ImF1dGhvciIsInR5cGUiOnsidHlwZSI6InJlY29yZCIsIm5hbWUiOiJ1c2VyIiwiZmllbGRzIjpbeyJuYW1lIjoiaWQiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoidXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoidXJsIiwidHlwZSI6InN0cmluZyJ9LHsibmFtZSI6ImlzX3ByaXZhdGUiLCJ0eXBlIjpbIm51bGwiLCJib29sZWFuIl19XX19LHsibmFtZSI6InZpZXdlciIsInR5cGUiOlsibnVsbCIsInVzZXIiXX0seyJuYW1lIjoidmlld2VkX2F0IiwidHlwZSI6ImRvdWJsZSJ9LHsibmFtZSI6ImZyb21fcmVwb3N0IiwidHlwZSI6ImJvb2xlYW4ifSx7Im5hbWUiOiJzdHJlYW1fa2luZCIsInR5cGUiOlsibnVsbCIsInN0cmluZyJdfSx7Im5hbWUiOiJzdHJlYW1faWQiLCJ0eXBlIjpbIm51bGwiLCJzdHJpbmciXX1dfQDGlvKecoM7+P/QnSim1+YpAuIDAkhlYWQxN2RjNy1hNjQ1LTRmOWUtYTQxNi02ZDVkNGQyZDQ5ZjQMMTg0NDQycM5I6rQy1kFKW3sia2luZCI6InRleHQiLCJkYXRhIjoiZG9wZSBzaG9lcyJ9XQBiaHR0cHM6Ly9lbGxvLm5pbmphL21rL3Bvc3QveW9oNjNpaDJ4Z3NzYXY5aHlwMHQ0dwI0BG1rKmh0dHBzOi8vZWxsby5uaW5qYS9tawIAAggyMzcwFmFsYW5wZWFib2R5PGh0dHBzOi8vZWxsby5uaW5qYS9hbGFucGVhYm9keQIAyxAHMYk81kEAAgxyZWNlbnQCAMaW8p5ygzv4/9CdKKbX5ik=",
          "PartitionKey" => "ead17dc7-a645-4f9e-a416-6d5d4d2d49f4-post_was_viewed",
          "SequenceNumber" => "49571180486878550058857500677839353996334974006682714130"
        }
      ]
    }}
  end

  def client_execute(operation) do
    operation
    |> IO.inspect
    |> ExAws.request
    |> IO.inspect
    flunk "Unhandled ExAws Operation"
  end
end
