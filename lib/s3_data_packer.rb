require 'csv'
require 'json'

require "s3_data_packer/version"
require 's3_data_packer/configuration'
require 's3_data_packer/package'
require 's3_data_packer/packer'

require 's3_data_packer/packages/csv'
require 's3_data_packer/packages/json'

require 's3_data_packer/sources/directory'
require 's3_data_packer/sources/bucket'

require 's3_data_packer/targets/s3'

module S3DataPacker
  class << self
    attr_reader :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def configure
      yield configuration
      self.configuraiton
    end

    def logger
      @logger ||= config.logger || Logger.new('log/s3_data_packer.log')
    end
  end
end
