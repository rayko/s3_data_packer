class FakeAwsCredentials
  def initialize(key, secret)
    { key: key, secret: secret }
  end
end

class FakeS3Resource
  def bucket(name)
    @bucket ||= FakeS3Bucket.new
  end
end

class FakeS3Bucket
  attr_reader :store

  def initialize
    @store = {}
  end

  def object(key)
    item = FakeS3Object.new(self, key)
  end

  def objects(prefix)
    @store.keys.map { |k| OpenStruct.new(key: k) }
  end
end

class FakeS3Object
  def initialize(fake_bucket, key)
    @bucket = fake_bucket
    @key = key
  end

  def get
    raise Aws::S3::Errors::NoSuchKey.new('', '') unless @bucket.store.keys.include?(@key)    
    data = @bucket.store[@key]
    OpenStruct.new body: StringIO.new(data)
  end

  def upload_file(filepath, metadata)
    data = File.read(filepath)
    @bucket.store[@key] = data
  end

  def exists?
    !@bucket.store[@key].nil?
  end
end
