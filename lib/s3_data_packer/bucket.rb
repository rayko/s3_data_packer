module S3DataPacker
  class Bucket
    attr_reader :name, :path

    def initialize opts = {}
      @name = opts[:name]
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

    def each_key
      bucket.objects(prefix: path).each do |item|
        yield item.key
      end
    end

    # def delete_keys(prefix)
    #   bucket.objects(prefix: prefix).each do |item|
    #     item.delete
    #   end
    # end

    # def delete(key)
    #   object(key).delete
    # end

    def exist?(key)
      object(key).exists?
    end

    def download(key)
      begin
        data = object(key).get
      rescue ::Aws::S3::Errors::InvalidRange
        logger.warn "Invalid range for #{key}"
        return nil
      rescue ::Aws::S3::Errors::NoSuchKey
        logger.warn "missing key #{key}"
        return nil
      end
      data.body.read
    end

    def upload(file, opts={})
      raise ArgumentError, 'File does not exist' unless File.exist?(file)
      key = "#{path}/#{File.basename(file)}"
      raise ArgumentError, "File #{File.basename(file)} already exists in target location" if exist?(key)
      metadata = opts
      metadata[:content_type] ||= file_mime_type(file)
      metadata[:content_disposition] ||= 'attachement'

      begin
        object(key).upload_file(file, metadata)
        logger.info "Uploaded #{file} to s3://#{name}/#{key}"
      rescue ::Aws::S3::Errors::InternalError
        logger.warn "Aws::S3::Errors::InternalError while pushing"
        sleep(1)
        retry
      end
    end

    private

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
      @bucket ||= resource.bucket(name)
    end

    def resource
      @resource ||= ::Aws::S3::Resource.new(region: region, credentials: credentials)
    end

  end
end
