require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @config = S3DataPacker::Configuration.new
  end

  def test_logger_attr
    assert_respond_to @config, :logger
    assert_respond_to @config, :logger=
  end

  def test_thread_count_attr
    assert_respond_to @config, :thread_count
    assert_respond_to @config, :thread_count=
  end

  def test_thread_sleep_time_attr
    assert_respond_to @config, :thread_sleep_time
    assert_respond_to @config, :thread_sleep_time=
  end

  def test_thread_lock_wait_time_attr
    assert_respond_to @config, :thread_lock_wait_time
    assert_respond_to @config, :thread_lock_wait_time=
  end

  def test_max_queue_size_attr
    assert_respond_to @config, :max_queue_size
    assert_respond_to @config, :max_queue_size=
  end

  def test_max_queue_wait_attr
    assert_respond_to @config, :max_queue_wait
    assert_respond_to @config, :max_queue_wait=
  end

  def test_workdir_attr
    assert_respond_to @config, :workdir
    assert_respond_to @config, :workdir=
  end

  def test_cleanup_batch_attr
    assert_respond_to @config, :cleanup_batch
    assert_respond_to @config, :cleanup_batch=
  end

  def test_compress_batch_attr
    assert_respond_to @config, :compress_batch
    assert_respond_to @config, :compress_batch=
  end

  def test_compres_batch?
    assert_respond_to @config, :compress_batch?
  end

  def test_cleanup_batch?
    assert_respond_to @config, :cleanup_batch?
  end

  def test_default_values
    assert_equal 2, @config.thread_count
    assert_equal 1, @config.thread_sleep_time
    assert_equal 1, @config.thread_lock_wait_time
    assert_equal 10000, @config.max_queue_size
    assert_equal 5, @config.max_queue_wait
    assert_equal 'tmp/s3_data_packer', @config.workdir
    assert_equal true, @config.cleanup_batch
    assert_equal true, @config.compress_batch
    assert_equal true, @config.cleanup_batch?
    assert_equal true, @config.compress_batch?
  end

  def test_default_s3_credentials
    @config.s3_api_key = 'lol'
    @config.s3_api_secret = 'cat'
    assert @config.default_s3_credentials != nil
    assert Aws::Credentials === @config.default_s3_credentials
    assert @config.default_s3_credentials.access_key_id == @config.s3_api_key
  end
end
