# Fake output for testing packer logic.
class FakeOutput
  def initialize file_store
    @counter = 0
    @repo = []
    @max_items = 10
    @store = file_store
  end

  def path
    "virtual_test_file_#{@counter}.bla"
  end
  
  def append_data! data
    @repo << data
  end

  def full?
    return false unless @repo
    @repo.size >= @max_items
  end

  def new_file!
    @counter += 1
    @repo = []
  end

  def finalize!
    @store.set path, @repo.join("\n")
    @repo = []
    path
  end

end
