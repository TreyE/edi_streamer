defmodule EdiStreamer.StreamerStateTest do
  use ExUnit.Case
  doctest EdiStreamer.StreamerState

  test "parse as stream" do
    {:ok, f} = :file.open("b2b_edi.csv", [:read, :binary])
    state = EdiStreamer.StreamerState.new("*", "~", f)
    stream = EdiStreamer.StreamerState.as_stream(state)
    Enum.each(stream,
    fn x -> IO.puts("Data: #{inspect x}") end)
  end
end
