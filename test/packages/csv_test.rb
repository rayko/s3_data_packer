require 'test_helper'

class CSVTest < Minitest::Test
  def setup
    @package = S3DataPacker::Packages::CSV.new
  end

  def has_open_file_method
    assert_equal @package.respond_to?(:open_file), true
  end

  def something
    assert false
  end
end
