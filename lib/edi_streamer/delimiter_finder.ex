defmodule EdiStreamer.DelimiterFinder do
  @spec find_delimiters(any) :: {:ok, binary, binary} | {:error, term}
  def find_delimiters(io_thing) do
    EdiStreamer.IoAble.rewind(io_thing)
    case EdiStreamer.IoAble.pread(io_thing, 3, 1) do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      {:ok, f_sep} ->
         EdiStreamer.IoAble.rewind(io_thing)
         find_s_separator(io_thing, f_sep, 0)
    end
  end

  defp find_s_separator(io_thing, f_sep, 16) do
    case EdiStreamer.IoAble.binread(io_thing, 2) do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      <<_::8, s_sep::binary>> -> 
        EdiStreamer.IoAble.rewind(io_thing)
        {:ok, f_sep, s_sep}
    end
  end

  defp find_s_separator(io_thing, f_sep, f_seps_found) do
    case EdiStreamer.IoAble.binread(io_thing, 1) do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      ^f_sep -> find_s_separator(io_thing, f_sep, f_seps_found + 1)
      _ -> find_s_separator(io_thing, f_sep, f_seps_found)
    end
  end
end
