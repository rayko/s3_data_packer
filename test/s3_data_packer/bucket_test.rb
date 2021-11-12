require 'test_helper'

class BucketTest < Minitest::Test
  def setup
    @bucket = S3DataPacker::Bucket.new bucket_name: 'test', path: 'testing/this'
  end

  def with_fake_s3 &block
    @fake_resource = FakeS3Resource.new
    @bucket.stub :resource, @fake_resource do
      yield
    end
  end

  def test_logger
    with_fake_s3 do
      assert @bucket.logger == S3DataPacker.logger
    end
  end

  def test_region
    with_fake_s3 do
      assert @bucket.region == S3DataPacker.config.s3_region
    end
  end

  def test_credentials
    with_fake_s3 do
      assert @bucket.credentials == S3DataPacker.config.default_s3_credentials
    end
  end

  def test_custom_credentials
    bucket = S3DataPacker::Bucket.new bucket_name: 'test', credentials: 'ASD'
    assert bucket.credentials == 'ASD'
  end

  def test_custom_region
    bucket = S3DataPacker::Bucket.new bucket_name: 'test', region: 'ASD'
    assert bucket.region == 'ASD'
  end

  def test_provided_path
    bucket = S3DataPacker::Bucket.new bucket_name: 'test', path: 'somewhere/else'
    assert bucket.path == 'somewhere/else'
  end

  def test_each_key
    with_fake_s3 do
      @fake_resource.bucket('test').store['subdir1/test.txt'] = 'asd qwe'
      @fake_resource.bucket('test').store['subdir1/test2.txt'] = 'zxc asd'
      @fake_resource.bucket('test').store['subdir1/test3.txt'] = 'qwe zxc'
      items = []
      @bucket.each_key { |k| items << k }
      assert items.include? 'subdir1/test.txt'
      assert items.include? 'subdir1/test2.txt'
      assert items.include? 'subdir1/test3.txt'
    end
  end

  def test_exist
    with_fake_s3 do
      @fake_resource.bucket('test').store['subdir1/test.txt'] = 'asd qwe'
      assert @bucket.exist?('subdir1/test.txt')
      assert !@bucket.exist?('subdir1/test2.txt')
    end
  end

  def test_download
    with_fake_s3 do
      @fake_resource.bucket('test').store['subdir1/test.txt'] = 'asd qwe'
      assert @bucket.download('subdir1/test.txt') == 'asd qwe'
      assert @bucket.download('subdir1/test2.txt') == nil
    end
  end

  def test_upload
    with_fake_s3 do
      file = File.open('tmp/upload_test.txt', 'w') { |f| f << "This is a test" }
      @bucket.upload file.path
      assert @fake_resource.bucket('test').store.keys.size == 1
      assert @fake_resource.bucket('test').store.values.first == "This is a test"
      File.delete(file.path)
    end
  end
end
