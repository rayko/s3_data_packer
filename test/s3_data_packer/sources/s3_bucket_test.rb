require 'test_helper'

class S3BuckeTest < Minitest::Test
  def setup
    @source = S3DataPacker::Sources::S3Bucket.new bucket_name: 'test', path: 'testing/this'
  end

  def with_fake_s3 &block
    @fake_resource = FakeS3Resource.new
    @source.stub :resource, @fake_resource do
      yield
    end
  end

  def test_name
    with_fake_s3 do
      assert @source.name == "s3://#{@source.bucket_name}/#{@source.path}"
    end
  end

  def test_each
    with_fake_s3 do
      @fake_resource.bucket('test').store["dir/file1.txt"] = "asd"
      @fake_resource.bucket('test').store["dir/file2.txt"] = "qwe"
      @fake_resource.bucket('test').store["dir/file3.txt"] = "zxc"
      items = []
      @source.each { |i| items << i }
      assert items.include?('dir/file1.txt')
      assert items.include?('dir/file2.txt')
      assert items.include?('dir/file3.txt')
    end
  end

  def test_fetch
    with_fake_s3 do
      @fake_resource.bucket('test').store["dir/file1.txt"] = "asd"
      assert @source.fetch('dir/file1.txt') == 'asd'
    end
  end
  
end
