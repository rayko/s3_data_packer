require 'test_helper'

class QueueTest < Minitest::Test
  def setup
    @queue = S3DataPacker::Queue.new
  end

  def test_methods
    assert_respond_to @queue, :total_items
    assert_respond_to @queue, :max_items
    assert_respond_to @queue, :wait_time
    assert_respond_to @queue, :add!
    assert_respond_to @queue, :fetch!
    assert_respond_to @queue, :size
    assert_respond_to @queue, :reset!
    assert_respond_to @queue, :items
  end

  def test_custom_max_items
    queue = S3DataPacker::Queue.new max_items: 10
    assert_equal queue.max_items, 10
  end

  def test_default_max_items
    assert_equal @queue.max_items, S3DataPacker.config.max_queue_size
  end

  def test_custom_wait_time
    queue = S3DataPacker::Queue.new wait_time: 20
    assert_equal queue.wait_time, 20
  end

  def test_default_max_items
    assert_equal @queue.wait_time, S3DataPacker.config.max_queue_wait
  end

  def test_add
    @queue.add! 'lolcat'
    assert_includes @queue.items, 'lolcat'
    assert_equal @queue.size, 1
  end

  def test_adding_duplicates
    @queue.add! 'lolcat'
    @queue.add! 'lolcat'
    assert_equal @queue.size, 2
  end

  def test_fetch_with_item
    @queue.add! 'lolcat'
    item = @queue.fetch!
    assert_equal 'lolcat', item
    assert_equal @queue.size, 0
  end

  def test_fetch_with_no_items
    assert_nil @queue.fetch!
  end

  def test_size
    assert_equal @queue.size, 0
    @queue.add! 'lolcat'
    @queue.add! 'madcat'
    assert_equal @queue.size, 2
  end

  def test_item_count
    5.times{ @queue.add!('lolcat') }
    3.times{ @queue.fetch! }

    assert_equal @queue.total_items, 5
  end

  def test_reset
    3.times { @queue.add!('lolcat') }
    @queue.reset!
    assert_equal @queue.size, 0
    assert_equal @queue.total_items, 0
    assert_empty @queue.items
  end
end
