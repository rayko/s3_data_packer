# Fake source for testing packer.
class FakeSource
  class FakeError < StandardError; end

  attr_reader :items

  def initialize
    @items = []
  end

  def raise_error_once
    @explode = true
  end

  def name
    "Test Source"
  end

  def each &block
    if @explode
      @explode = false
      raise FakeError, 'I exploded'
    end
    items.each{ |i| yield i }
  end

  def fetch(item_id)
    item_id
  end
end
