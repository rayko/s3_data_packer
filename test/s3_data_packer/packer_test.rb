require 'test_helper'

class PackerTest < Minitest::Test
  def setup
    S3DataPacker.config.thread_count = 1
    @file_store = FileStore.new
    @source = FakeSource.new
    @target = FakeTarget.new @file_store
    @output = FakeOutput.new @file_store
    @packer = S3DataPacker::Packer.new source: @source, target: @target, output: @output
  end

  def test_summary
    assert S3DataPacker::Summary === @packer.summary
    assert @packer.summary.stats.empty?
  end

  def test_logger
    assert @packer.logger == S3DataPacker.logger
  end

  def test_workers
    assert S3DataPacker::ThreadSet === @packer.workers
  end

  def test_pack_normal_conditions
    # should produce 2 bataches of 10 and 5 things
    15.times { |n| @source.items << "item-#{n}" }
    @packer.pack!
    assert @target.files.keys.size == 2
    assert @target.files.values.first.split("\n").size == 10
    assert @target.files.values.last.split("\n").size == 5
    assert @packer.workers.dead?
  end

  def test_pack_with_error_iterating
    # should not produce any batches, failure happens right on first item read
    15.times { |n| @source.items << "item-#{n}" }
    @source.raise_error_once
    assert_raises(FakeSource::FakeError) { @packer.pack! }
    sleep(0.5)
    assert @target.files.empty?
    assert @packer.workers.dead?
  end

  def test_pack_with_dead_workers
    # If workers die, it should raise an exception to stop everything
    15.times { |n| @source.items << "item-#{n}" }
    @packer.workers.stub :dead?, true do
      assert_raises(S3DataPacker::Packer::Error::DeadWorkers) { @packer.pack! }
    end
  end
end
