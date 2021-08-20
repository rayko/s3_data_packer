require "s3_data_packer/version"
require 's3_data_packer/configuration'

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
  end
end
