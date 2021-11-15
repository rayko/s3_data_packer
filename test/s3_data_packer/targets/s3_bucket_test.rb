require 'test_helper'

class S3BucketTargetTest < Minitest::Test
  def setup
    @target = S3DataPacker::Targets::S3Bucket.new bucket_name: 'test', path: 'testing/this'
  end

  def with_fake_s3 &block
    @fake_resource = FakeS3Resource.new
    @target.stub :resource, @fake_resource do
      yield
    end
  end

  def test_name
    with_fake_s3 do
      assert @target.name == "s3://#{@target.bucket_name}/#{@target.path}"
    end
  end

  def test_save_file
    with_fake_s3 do
      file = File.open('tmp/upload_target_file_test.txt', 'w') { |f| f << 'asd qwe' }
      @target.save_file file.path
      assert @fake_resource.bucket('test').store.keys.size == 1
      assert @fake_resource.bucket('test').store.values.first == 'asd qwe'
      File.delete(file.path) if File.exist?(file.path)
    end
  end

end
