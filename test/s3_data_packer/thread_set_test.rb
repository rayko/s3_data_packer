require 'test_helper'

class ThreadSetTest < Minitest::Test
  def setup
    @set = S3DataPacker::ThreadSet.new
  end

  def test_methods
    assert_respond_to @set, :lock
    assert_respond_to @set, :workers
    assert_respond_to @set, :wait_time
    assert_respond_to @set, :lock_wait_time
    assert_respond_to @set, :thread_count
    assert_respond_to @set, :dead?
    assert_respond_to @set, :kill!
    assert_respond_to @set, :finish!
    assert_respond_to @set, :finished?
    assert_respond_to @set, :log
    assert_respond_to @set, :wait!
    assert_respond_to @set, :spawn_thread!
    assert_respond_to @set, :spawn_threads!
    assert_respond_to @set, :reset!
  end

  def test_queue
    assert_kind_of S3DataPacker::Queue, @set.queue
  end

  def test_default_wait_time
    assert_equal @set.wait_time, S3DataPacker.config.thread_sleep_time
  end

  def test_defualt_thread_count
    assert_equal @set.thread_count, S3DataPacker.config.thread_count
  end

  def test_default_lock_wait_time
    assert_equal @set.lock_wait_time, S3DataPacker.config.thread_lock_wait_time
  end

  def test_no_default_workers
    assert_empty @set.workers
  end
  
  def test_lock_presence
    assert_kind_of Mutex, @set.lock
  end

  def test_finished?
    @set.queue.add! 'item'
    refute @set.finished?
    @set.finish!
    refute @set.finished?
    @set.queue.fetch!
    assert @set.finished?
  end

  def test_dead?
    @set.spawn_thread!('test') { |item| item }
    sleep(0.2) # Let the thread boot
    refute @set.dead?
    @set.kill!
    sleep(0.2) # Let the thread die
    assert @set.dead?
  end

  def test_reset_with_kill
    @set.spawn_thread!('test') {|item| item }
    sleep(0.2) # Let the thread boot
    refute_empty @set.workers
    @set.reset!
    refute_empty @set.workers
    @set.kill!
    sleep(0.2) # Let the thread die
    @set.reset!
    assert_empty @set.workers
  end

  def test_reset_with_normal_finish
    @set.spawn_thread!('test') {|item| item }
    sleep(0.2) # Let the thread boot
    refute_empty @set.workers
    @set.reset!
    refute_empty @set.workers
    @set.finish!
    sleep(1) # Thread will likely be sleeping so wait a bit
    @set.reset!
    assert_empty @set.workers
  end
end
