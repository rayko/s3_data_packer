require 'test_helper'

class JSONBatchTest < Minitest::Test

  def setup
    S3DataPacker.configure do |config|
      config.workdir = WORKDIR
    end
    @batch = S3DataPacker::JSONBatch.new
  end
        
  def test_methods
    assert_respond_to @batch, :workdir
    assert_respond_to @batch, :delimitter
    assert_respond_to @batch, :batch
    assert_respond_to @batch, :filename_generator
    assert_respond_to @batch, :generate_filename
    assert_respond_to @batch, :new_file!
    assert_respond_to @batch, :append_data!
    assert_respond_to @batch, :path
    assert_respond_to @batch, :close!
    assert_respond_to @batch, :delete!
    assert_respond_to @batch, :finalize!
  end

  def test_delimitter
    assert_equal @batch.delimitter, "\r\n"
  end

  def test_workdir
    assert_equal @batch.workdir, S3DataPacker.config.workdir
  end

  def test_filename_generator
    assert_kind_of Fiber, @batch.filename_generator
  end

  def test_generate_filename
    name = nil
    2.times do
      new_name = @batch.generate_filename
      refute_equal name, new_name
      assert @batch.path.include?('.json')
      sleep(1)
    end
  end

  def test_new_file!
    assert_kind_of File, @batch.new_file!
    assert_equal @batch.new_file!, @batch.batch
  end

  def test_append_data!
    json = {lolcat: 1, madcat: 'abc'}.to_json
    @batch.append_data! json
    assert_equal @batch.item_count, 1
    path = @batch.path
    @batch.close!
    assert_equal File.read(path), "#{json}#{@batch.delimitter}"
  end

  def test_path
    file = @batch.batch
    assert_equal @batch.path, file.path
  end

  def test_close!
    @batch.close!
    assert @batch.batch.closed?
  end

  def test_delete!
    path = @batch.path
    @batch.delete!
    refute File.exist?(path)
  end

  def test_finalize_compress
    S3DataPacker.config.compress_batch = true
    json = {lolcat: 1, madcat: 'abc'}.to_json
    @batch.append_data! json
    original_path = @batch.path
    final_path = @batch.finalize!
    assert File.exist?(final_path)
    assert final_path.include?('.gz')
    refute_equal final_path, original_path
    refute File.exist?(original_path)
  end

  def test_finalize_no_compress
    S3DataPacker.config.compress_batch = false
    json = {lolcat: 1, madcat: 'abc'}.to_json
    @batch.append_data! json
    original_path = @batch.path
    final_path = @batch.finalize!
    assert File.exist?(final_path)
    refute final_path.include?('.gz')
    assert_equal final_path, original_path
    assert File.exist?(original_path)
  end
end
