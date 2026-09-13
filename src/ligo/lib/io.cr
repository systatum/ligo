struct IOStringIterator
  include Iterator(String)

  def initialize(@io : IO, @chunk_size : Int32 = 4096)
  end

  def next : String | Iterator::Stop
    chunk = Bytes.new(@chunk_size)
    bytes_read = @io.read(chunk)
    return stop if bytes_read == 0
    String.new(chunk[0, bytes_read])
  end
end

class IO
  def each_string(chunk_size : Int32 = 4096)
    return IOStringIterator.new(self, chunk_size)
  end
end
