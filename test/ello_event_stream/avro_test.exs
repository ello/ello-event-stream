defmodule Ello.EventStream.AvroTest do
  use ExUnit.Case
  alias Ello.EventStream.Avro

  test "it parses avro into {type, map} tuple" do
    ocf_binary = File.read!("test/support/post_was_loved.avro")
    assert {"post_was_loved", data} = Avro.parse_ocf(ocf_binary)
    assert is_map(data)
    assert is_map(data["author"])
    assert is_map(data["lover"])
    assert data["author"]["id"] == "100001"
    assert data["loved_at"]
    assert data["lover"]["id"] == "100002"
  end
end
