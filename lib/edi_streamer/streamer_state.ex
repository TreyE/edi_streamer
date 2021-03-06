defmodule EdiStreamer.StreamerState do
  defstruct [:parse_state, :segment_index, :current_segment_start, :io_index, :fields, :current_field, :raw_segment, :buffer, :io_source, :field_separator, :segment_separator, :sub_delimiter]

  @type segment :: %EdiStreamer.Segment{}
  @type parse_state :: :in_field | :in_end
  @type streamer_state :: %EdiStreamer.StreamerState{
    buffer: binary,
    io_source: any,
    field_separator: byte,
    segment_separator: byte,
    sub_delimiter: byte,
    io_index: integer,
    parse_state: parse_state,
    current_segment_start: integer,
    fields: [binary],
    raw_segment: binary,
    segment_index: integer
  }

  @spec new(byte, byte, byte, any) :: streamer_state
  def new(f_separator, s_separator, sub_element_delim, io_thing) do
    %EdiStreamer.StreamerState{
      buffer: <<>>,
      io_source: io_thing,
      field_separator: f_separator,
      segment_separator: s_separator,
      sub_delimiter: sub_element_delim,
      parse_state: :in_field,
      current_segment_start: 0,
      io_index: 0,
      fields: [],
      current_field: <<>>,
      raw_segment: <<>>,
      segment_index: 0
    }
  end

  @spec as_stream(streamer_state) :: Stream.streamer_state
  def as_stream(state) do
    Stream.resource(
      fn -> state end,
      fn s -> step(s) end,
      fn s -> s end)
  end

  @spec step(streamer_state) :: {:halt, streamer_state} | {nonempty_list(segment), streamer_state}
  def step(%EdiStreamer.StreamerState{parse_state: :no_more_input} = state) do
    {:halt, state}
  end

  def step(state) do
    case state.buffer do
      <<>> -> 
        case pull_buffer(state) do
          {:ok, new_state} -> step(new_state)
          {:eof, new_state} -> convert_leftovers(new_state)
          other -> other
        end
      <<first_byte::binary-size(1), rest::binary>> ->
        f_separator = state.field_separator
        s_separator = state.segment_separator
        case {first_byte, state.parse_state} do
          {^f_separator, _} -> 
            step(%EdiStreamer.StreamerState{state | buffer: rest, io_index: (state.io_index + 1), current_field: <<>>, fields: [state.current_field|state.fields], parse_state: :in_field, raw_segment: state.raw_segment <> first_byte})
          {^s_separator, _} -> 
            step(%EdiStreamer.StreamerState{state | buffer: rest, io_index: (state.io_index + 1), current_field: <<>>, fields: [state.current_field|state.fields], parse_state: :in_end, raw_segment: state.raw_segment <> first_byte})
          {_, :in_end} -> case ((first_byte > <<64>>) and (first_byte < <<91>>)) do
                            true -> 
                              fields = Enum.reverse(state.fields)
                              segment = %EdiStreamer.Segment{
                                tag: Enum.fetch!(fields, 0),
                                fields: fields,
                                raw: state.raw_segment,
                                start_offset: state.current_segment_start,
                                end_offset: state.io_index - 1,
                                field_separator: state.field_separator,
                                segment_separator: state.segment_separator,
                                segment_index: state.segment_index,
                                sub_delimiter: state.sub_delimiter
                              }
                              new_state = %EdiStreamer.StreamerState{ state |
                                io_index: state.io_index + 1,
                                parse_state: :in_field,
                                buffer: rest,
                                current_field: first_byte,
                                fields: [],
                                current_segment_start: state.io_index,
                                segment_index: state.segment_index + 1,
                                raw_segment: first_byte
                              }
                              {[segment], new_state}
                            _ -> step(%EdiStreamer.StreamerState{state | buffer: rest, io_index: (state.io_index + 1), raw_segment: state.raw_segment <> first_byte})
                          end
          _ -> step(%EdiStreamer.StreamerState{state | buffer: rest, io_index: (state.io_index + 1), current_field: state.current_field <> first_byte, raw_segment: state.raw_segment <> first_byte})
        end
    end
  end

  defp convert_leftovers(state) do
    case {state.parse_state, state.current_field, state.fields} do
      {:in_end, _, _} ->
        fields = Enum.reverse(state.fields)
        segment = %EdiStreamer.Segment{
          tag: Enum.fetch!(fields, 0),
          fields: fields,
          raw: state.raw_segment,
          start_offset: state.current_segment_start,
          end_offset: state.io_index,
          field_separator: state.field_separator,
          segment_separator: state.segment_separator,
          segment_index: state.segment_index,
          sub_delimiter: state.sub_delimiter
        }
        {
          [segment],
          %EdiStreamer.StreamerState{state | parse_state: :no_more_input}
        }
      {_, <<>>, []} -> {:halt, state}
      _ -> 
        fields = Enum.reverse([state.current_field|state.fields])
        segment = %EdiStreamer.Segment{
          tag: Enum.fetch!(fields, 0),
          fields: fields,
          raw: state.raw_segment,
          start_offset: state.current_segment_start,
          end_offset: state.io_index,
          field_separator: state.field_separator,
          segment_separator: state.segment_separator,
          segment_index: state.segment_index,
          sub_delimiter: state.sub_delimiter
        }
        {
          [segment],
          %EdiStreamer.StreamerState{state | parse_state: :no_more_input}
        }
    end
  end

  defp pull_buffer(state) do
    {new_io_thing, data} = EdiStreamer.IoAble.read_chunk(state.io_source)
    case data do
      :eof -> {:eof, %EdiStreamer.StreamerState{state | io_source: new_io_thing}} 
      {:error, reason} -> {:error, reason}
      data -> {:ok, %EdiStreamer.StreamerState{state | io_source: new_io_thing, buffer: data}}
    end
  end

end
