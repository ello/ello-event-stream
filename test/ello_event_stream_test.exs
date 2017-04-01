defmodule Ello.EventStreamTest do
  use ExUnit.Case
  alias Ello.EventStream


  @tag :integration
  test "consuming from kinesis stream" do
  end


  test "it parses avro into events" do
    avro = File.read!("post_was_loved_single.avro")
    event = Ello.EventStream.parse_avro(avro)
    IO.inspect(event)
    assert event.type == "post_was_loved"
    assert [data] = event.data
    assert data["author"]["id"] == "100001"
    assert data["post"]["id"] == "1"
  end
end
