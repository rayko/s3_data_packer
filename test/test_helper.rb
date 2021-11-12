require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'
require 'fake_s3'
require 'byebug'

require 's3_data_packer'
WORKDIR = 'tmp/test_data'

unless Dir.exist?(WORKDIR)
  Dir.mkdir 'tmp' unless Dir.exist?('tmp')
  Dir.mkdir 'tmp/test_data'
end

