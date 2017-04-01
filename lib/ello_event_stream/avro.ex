defmodule Ello.EventStream.Avro do

  @doc """
  Parse an Avro OCF format binary.
  """
  def parse_ocf(binary) do
    {_header, schema, data} = :avro_ocf.decode_binary(binary)
    {:avro_record_type, type, _, _,  _, _definition, _type, _} = schema
    {type, deep_into(data)}
  end

  # Convert lists of tuples into maps.
  defp deep_into([input]), do: deep_into(input)
  defp deep_into(input) when is_list(input), do: deep_into(input, %{})
  defp deep_into(other), do: other
  defp deep_into([], output), do: output
  defp deep_into([{k, v} | rest], output) do
    deep_into(rest, Map.put(output, k, deep_into(v)))
  end
  defp deep_into(other, _output), do: other

end
