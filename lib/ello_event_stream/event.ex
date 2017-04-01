defmodule Ello.EventStream.Event do
  alias Ello.EventStream.Avro
  defstruct type: "", data: [], shard: nil, sequence_number: nil, raw: ""

  def from_kinesis(record) do
    parse_raw(%__MODULE__{
      raw:             record["Data"],
      sequence_number: record["SequenceNumber"],
      shard:           record["PartitionKey"],
    })
  end

  defp parse_raw(%__MODULE__{raw: raw} = event) when not is_nil(raw) do
    {type, data} = raw
                   |> Base.decode64!
                   |> Avro.parse_ocf
    %{event | data: data, type: type}
  end
end
