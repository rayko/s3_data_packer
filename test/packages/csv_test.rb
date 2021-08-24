require 'test_helper'

class CSVTest < Minitest::Test
  def setup
    @package = S3DataPacker::Packages::CSV.new
  end

  def test_method_existence
    assert_respond_to @package, :open_file
    assert_respond_to @package, :append_item
  end

  def test_open_new_file_with_no_headers
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    output.close
    assert_match "", File.read(output.path)
  end

  def test_open_new_file_with_headers
    headers = %w[col1 col2 col3]
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename, headers
    output.close
    assert_match headers.join(','), File.read(output.path)
  end

  def test_opened_file
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    assert !output.closed?
    assert File.exist?("#{WORKDIR}/#{filename}.csv")
    assert_kind_of ::CSV, output
  end

  def test_append_item_adds_row
    filename = "#{Time.now.to_i}_test"
    row = %w[val1 val2 val3]
    output = @package.open_file WORKDIR, filename
    @package.append_item row, output
    output.close
    assert_match row.join(','), File.read(output.path)
  end

  def test_append_item_fails_with_non_array
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    assert_raises(ArgumentError) { @package.append_item('bla', output) }
    output.close
  end

  def test_append_item_fails_with_no_csv_target
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    assert_raises(ArgumentError) { @package.append_item(%w[val1 val2], "someting") }
    output.close
  end

end
