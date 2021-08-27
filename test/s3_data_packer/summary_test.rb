require 'test_helper'

class SummaryTest < Minitest::Test
  def setup
    @summary = S3DataPacker::Summary.new
  end

  def test_methods
    assert_respond_to @summary, :stats
    assert_respond_to @summary, :count_item
    assert_respond_to @summary, :count_processed
    assert_respond_to @summary, :count_batch
    assert_respond_to @summary, :set_time
    assert_respond_to @summary, :total_items
    assert_respond_to @summary, :processed
    assert_respond_to @summary, :batches
    assert_respond_to @summary, :elapsed
    assert_respond_to @summary, :flush!
    assert_respond_to @summary, :reset!
  end

  def test_stats
    assert_kind_of Hash, @summary.stats
  end

  def test_count_item
    @summary.count_item
    assert_equal @summary.stats.size, 1
    assert_equal @summary.stats.keys, [:total_items]
    assert_equal @summary.stats[:total_items], 1
    assert_equal @summary.total_items, 1
  end

  def test_count_processed
    @summary.count_processed
    assert_equal @summary.stats.size, 1
    assert_equal @summary.stats.keys, [:processed]
    assert_equal @summary.stats[:processed], 1
    assert_equal @summary.processed, 1
  end

  def test_count_batch
    @summary.count_batch
    assert_equal @summary.stats.size, 1
    assert_equal @summary.stats.keys, [:batches]
    assert_equal @summary.stats[:batches], 1
    assert_equal @summary.batches, 1
  end

  def test_set_time
    time = Time.now
    @summary.set_time time, (time + 10)
    assert_equal @summary.stats.size, 1
    assert_equal @summary.stats.keys, [:elapsed]
    assert_equal @summary.stats[:elapsed], '10 seconds'
    assert_equal @summary.elapsed, '10 seconds'
  end

  def test_flush
    3.times { @summary.count_item }
    2.times { @summary.count_processed }
    @summary.count_batch
    time = Time.now
    @summary.set_time time, (time + 20)
    expected_output = ['Summary:', 
                       'Total Items: 3', 
                       'Processed Items: 2', 
                       'Batches: 1', 
                       'Elapsed: 20 seconds'].join("\n")
    assert_equal @summary.flush!, expected_output
    assert_equal @summary.stats, {}
  end

  def test_reset
    3.times { @summary.count_item }
    2.times { @summary.count_processed }
    @summary.count_batch
    time = Time.now
    @summary.set_time time, (time + 20)
    @summary.reset!
    assert_equal @summary.stats, {}
  end

  def test_spawn_state
    assert_equal @summary.stats, {}
    assert_equal 0, @summary.total_items
    assert_equal 0, @summary.processed
    assert_equal 0, @summary.batches
    assert_nil @summary.elapsed
  end
end
