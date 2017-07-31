defmodule EdiStreamer.Segment do
  defstruct [:start_offset, :end_offset, :fields, :tag, :raw, :field_separator, :segment_separator, :segment_index]
end
