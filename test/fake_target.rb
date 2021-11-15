# Fake target for testing packer.
class FakeTarget
  attr_reader :files

  def initialize file_store
    @files = {}
    @store = file_store
  end

  def name
    'Test Target'
  end

  def save_file path
    @files[path] = @store.get(path)
  end
end
