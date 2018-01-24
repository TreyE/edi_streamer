defmodule EdiStreamer.DelimiterFinder do
  @spec find_delimiters(any) :: {:ok, binary, binary, binary, any} | {:error, term}
  def find_delimiters(io_thing) do
    rewound_io_thing = EdiStreamer.IoAble.rewind(io_thing)
    {new_io_thing, data} = EdiStreamer.IoAble.pread(rewound_io_thing, 3, 1)
    case data do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      {:ok, f_sep} ->
         searchable_io_thing = EdiStreamer.IoAble.rewind(new_io_thing)
         find_s_separator(searchable_io_thing, f_sep, 0)
    end
  end

  defp find_s_separator(io_thing, f_sep, 16) do
    {new_io_thing, data} = EdiStreamer.IoAble.binread(io_thing, 2)
    case data do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      <<sub_delimiter::binary-size(1), s_sep::binary>> -> 
        rewound_io_thing = EdiStreamer.IoAble.rewind(new_io_thing)
        {:ok, f_sep, s_sep, sub_delimiter, rewound_io_thing}
    end
  end

  defp find_s_separator(io_thing, f_sep, f_seps_found) do
    {new_io_thing, data} = EdiStreamer.IoAble.binread(io_thing, 1)
    case data do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      ^f_sep -> find_s_separator(new_io_thing, f_sep, f_seps_found + 1)
      _ -> find_s_separator(new_io_thing, f_sep, f_seps_found)
    end
  end
end
