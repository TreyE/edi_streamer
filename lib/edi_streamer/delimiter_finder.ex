defmodule EdiStreamer.DelimiterFinder do
  @spec find_delimiters(any) :: {:ok, binary, binary} | {:error, term}
  def find_delimiters(io_thing) do
    :file.position(io_thing, 0)
    case :file.pread(io_thing, 3, 1) do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      {:ok, f_sep} ->
         :file.position(io_thing, 0)
         find_s_separator(io_thing, f_sep, 0)
    end
  end

  defp find_s_separator(io_thing, f_sep, 16) do
    case IO.binread(io_thing, 2) do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      <<_::8, s_sep::binary>> -> 
        :file.position(io_thing, 0)
        {:ok, f_sep, s_sep}
    end
  end

  defp find_s_separator(io_thing, f_sep, f_seps_found) do
    case IO.binread(io_thing, 1) do
      :eof -> {:error, :eof}
      {:error, io_e} -> {:error, {:io_error, io_e}}
      ^f_sep -> find_s_separator(io_thing, f_sep, f_seps_found + 1)
      _ -> find_s_separator(io_thing, f_sep, f_seps_found)
    end
  end
end
