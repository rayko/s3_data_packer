module S3DataPacker
  module Sources
    
    class S3Bucket < S3DataPacker::Bucket
      def name
        "s3://#{bucket_name}/#{path}"
      end

      def each(&block)
        each_key do |key|
          yield key
        end
      end

      def fetch(key)
        download(key)
      end
    end

  end
end
