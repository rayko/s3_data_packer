module S3DataPacker
  class Bucket
    attr_reader :bucket_name, :path

    def initialize opts = {}
      @bucket_name = opts[:bucket_name]
      @credentials = opts[:credentials]
      @region = opts[:region]
      @path = opts[:path]
    end

    def credentials
      @credentials ||= S3DataPacker.config.default_s3_credentials
    end

    def region
      @region ||= S3DataPacker.config.s3_region
    end

    def logger
      @logger ||= S3DataPacker.logger
    end

    def each_key &block
      bucket.objects(prefix: path).each do |item|
        yield item.key
      end
    end

    def exist?(key)
      request! { object(key).exists? }
    end

    def download(key)
      data = request! { object(key).get }
      logger.warn "missing key #{key}" unless data
      return nil unless data
      data.body.read
    end

    def upload(file, opts={})
      raise ArgumentError, 'File does not exist' unless File.exist?(file)
      key = "#{path}/#{File.basename(file)}"
      raise ArgumentError, "File #{File.basename(file)} already exists in target location" if exist?(key)
      metadata = opts
      metadata[:content_type] ||= file_mime_type(file)
      metadata[:content_disposition] ||= 'attachement'
      request! { object(key).upload_file(file, metadata) }
      logger.info "Uploaded #{file} to s3://#{bucket_name}/#{key}"
    end

    private

    def request! &block
      begin
        yield
      rescue Aws::S3::Errors::InternalError
        logger.warn "Aws::S3::Errors::InternalError, retrying in 1 second"
        sleep(1)
        retry
      rescue Aws::S3::Errors::InvalidRange
        logger.warn "Invalid range"
        return nil
      rescue Aws::S3::Errors::NoSuchKey
        return nil
      end
    end

    def client
      @client ||= ::Aws::S3::Client.new(region: region, credentials: credentials)
    end

    def file_mime_type(file)
      begin
        MIME::Types.type_for(file).first.content_type
      rescue StandardError
        logger.error "Could not guess MIME type of #{file}"
      end
    end

    def object(key)
      bucket.object(key)
    end

    def bucket
      @bucket ||= resource.bucket(bucket_name)
    end

    def resource
      @resource ||= ::Aws::S3::Resource.new(region: region, credentials: credentials)
    end

  end
end
