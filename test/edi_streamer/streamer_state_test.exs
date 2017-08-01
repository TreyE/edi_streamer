defmodule EdiStreamer.StreamerStateTest do
  use ExUnit.Case
  doctest EdiStreamer.StreamerState

  test "parse as stream" do
    {:ok, f} = :file.open("b2b_edi.csv", [:read, :binary])
    {:ok, f_sep, s_sep} = EdiStreamer.DelimiterFinder.find_delimiters(f)
    state = EdiStreamer.StreamerState.new(f_sep, s_sep, f)
    stream = EdiStreamer.StreamerState.as_stream(state)
    Enum.each(stream,
    fn x -> IO.puts("Data: #{inspect x}") end)
  end
end
