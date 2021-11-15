# Simple virtual storage to mimic files within tests.
class FileStore
  def initialize
    @store = {}
  end

  def set key, data
    @store[key] = data
  end

  def get key
    @store[key]
  end

  def del key
    @store.delete key
  end
end
