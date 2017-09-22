defprotocol EdiStreamer.IoAble do
  def rewind(io_able)

  def read_chunk(io_able)

  def binread(io_able, size)

  def pread(io_able, idx, size)
end

defimpl EdiStreamer.IoAble, for: Any do
  def rewind(io_able) do
   :file.position(io_able, 0)
  end

  def read_chunk(io_able) do
    IO.binread(io_able, 4096)
  end

  def binread(io_able, size) do
    IO.binread(io_able, size)
  end

  def pread(io_able, idx, size) do
    :file.pread(io_able, idx, size)
  end
end
