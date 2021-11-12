$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "s3_data_packer"
require 'byebug'

WORKDIR = 'tmp/test_data'

unless Dir.exist?(WORKDIR)
  Dir.mkdir 'tmp' unless Dir.exist?('tmp')
  Dir.mkdir 'tmp/test_data'
end



require "minitest/autorun"
require 'fake_s3'

