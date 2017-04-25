defmodule Ello.EventStream.EventTest do
  use ExUnit.Case
  alias Ello.EventStream.Event

  test "it converts kinesis events into events" do
    assert %Event{} = event = Event.from_kinesis(post_was_viewed_record())
    assert event.type == "post_was_viewed"
    assert event.sequence_number
    assert event.shard
    assert is_map(event.data)
    assert is_map(event.data["author"])
    assert is_map(event.data["viewer"])
  end

  defp post_was_viewed_record do
    %{
      "ApproximateArrivalTimestamp" => 1491071111.203,
      "Data" => "T2JqAQQUYXZyby5jb2RlYwhudWxsFmF2cm8uc2NoZW1hiAt7InR5cGUiOiJyZWNvcmQiLCJuYW1lIjoicG9zdF93YXNfdmlld2VkIiwiZmllbGRzIjpbeyJuYW1lIjoicG9zdCIsInR5cGUiOnsidHlwZSI6InJlY29yZCIsIm5hbWUiOiJwb3N0IiwiZmllbGRzIjpbeyJuYW1lIjoiaWQiLCJ0eXBlIjoic3RyaW5nIn0seyJuYW1lIjoiY3JlYXRlZF9hdCIsInR5cGUiOiJkb3VibGUifSx7Im5hbWUiOiJib2R5IiwidHlwZSI6InN0cmluZyJ9LHsibmFtZSI6Im5zZnciLCJ0eXBlIjoiYm9vbGVhbiJ9LHsibmFtZSI6InVybCIsInR5cGUiOiJzdHJpbmcifV19fSx7Im5hbWUiOiJhdXRob3IiLCJ0eXBlIjp7InR5cGUiOiJyZWNvcmQiLCJuYW1lIjoidXNlciIsImZpZWxkcyI6W3sibmFtZSI6ImlkIiwidHlwZSI6InN0cmluZyJ9LHsibmFtZSI6InVzZXJuYW1lIiwidHlwZSI6InN0cmluZyJ9LHsibmFtZSI6InVybCIsInR5cGUiOiJzdHJpbmcifSx7Im5hbWUiOiJpc19wcml2YXRlIiwidHlwZSI6WyJudWxsIiwiYm9vbGVhbiJdfV19fSx7Im5hbWUiOiJ2aWV3ZXIiLCJ0eXBlIjpbIm51bGwiLCJ1c2VyIl19LHsibmFtZSI6InZpZXdlZF9hdCIsInR5cGUiOiJkb3VibGUifSx7Im5hbWUiOiJmcm9tX3JlcG9zdCIsInR5cGUiOiJib29sZWFuIn0seyJuYW1lIjoic3RyZWFtX2tpbmQiLCJ0eXBlIjpbIm51bGwiLCJzdHJpbmciXX0seyJuYW1lIjoic3RyZWFtX2lkIiwidHlwZSI6WyJudWxsIiwic3RyaW5nIl19XX0Al5oSxw5wFHytLdbEuvWWlQKkAwwxODQ0OTUJ+UgesTbWQUBbeyJraW5kIjoidGV4dCIsImRhdGEiOiJoZWxsbyJ9XQBmaHR0cHM6Ly9lbGxvLm5pbmphL3NlYW4vcG9zdC95Y2NxZjJ6eGVkdHY4dTZsYWhnNnNhBjU2NQhzZWFuLmh0dHBzOi8vZWxsby5uaW5qYS9zZWFuAgACCDIzNzAWYWxhbnBlYWJvZHk8aHR0cHM6Ly9lbGxvLm5pbmphL2FsYW5wZWFib2R5AgC9UsYh/DfWQQACCHBvc3QCDDE4NDQ5NZeaEscOcBR8rS3WxLr1lpU=",
      "PartitionKey" => "post_was_viewed",
      "SequenceNumber" => "49571180486900850804055921638699613526050896019325976610"
    }
  end
end
