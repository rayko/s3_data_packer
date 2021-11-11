module S3DataPacker
  module Targets

    class S3Bucket < S3DataPacker::Bucket
      def name
        "s3://#{bucket_name}/#{path}"
      end

      def save_file(filepath)
        upload(filepath)
      end
    end

  end
end
