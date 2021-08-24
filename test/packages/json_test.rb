require 'test_helper'

class JSONTest < Minitest::Test
  def setup
    @package = S3DataPacker::Packages::JSON.new
  end

  def test_method_existence
    assert_respond_to @package, :open_file
    assert_respond_to @package, :append_item
  end

  def test_open_new_file
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    output.close
    assert_match "", File.read(output.path)
  end

  def test_opened_file
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    assert !output.closed?
    assert File.exist?("#{WORKDIR}/#{filename}.json")
    assert_kind_of File, output
  end

  def test_append_item_adds_data
    filename = "#{Time.now.to_i}_test"
    data = {bla: 1, ble: 2}.to_json
    output = @package.open_file WORKDIR, filename
    @package.append_item data, output
    output.close
    assert_match "#{data}\r\n", File.read(output.path)
  end

  def test_append_item_fails_with_non_string
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    assert_raises(ArgumentError) { @package.append_item([1,2], output) }
    output.close
  end

  def test_append_item_fails_with_no_file_target
    filename = "#{Time.now.to_i}_test"
    output = @package.open_file WORKDIR, filename
    data = {bla: 1, ble: 2}.to_json
    assert_raises(ArgumentError) { @package.append_item(data, "someting") }
    output.close
  end

end
