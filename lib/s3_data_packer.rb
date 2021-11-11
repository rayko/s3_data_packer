require 'csv'
require 'json'
require 'logger'
require 'mime/types/full'
require 'aws-sdk-s3'

require "s3_data_packer/version"
require 's3_data_packer/configuration'
require 's3_data_packer/packer'
require 's3_data_packer/queue'
require 's3_data_packer/thread_set'
require 's3_data_packer/summary'
require 's3_data_packer/json_batch'
require 's3_data_packer/bucket'
require 's3_data_packer/filename_generator'

require 's3_data_packer/sources/object'
require 'S3_data_packer/sources/s3_bucket'

require 's3_data_packer/targets/s3_bucket'

module S3DataPacker
  class << self
    attr_reader :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def configure
      yield configuration
    end

    def logger
      @logger ||= config.logger || Logger.new('log/s3_data_packer.log')
    end
  end
end
