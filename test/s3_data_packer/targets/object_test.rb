require 'test_helper'

class TestTarget
  # This would be for the #save_file method
  def madcat(path)
    path
  end

  # And this would be for the #name method
  def bobcat
    "I'm a test LOL"
  end
end

class TargetObjectTest < Minitest::Test
  def test_methods
    source = S3DataPacker::Targets::Object.new object: Object.new
    assert_respond_to source, :name
    assert_respond_to source, :save_file
  end

  def test_save_file_method
    source = S3DataPacker::Targets::Object.new object: TestTarget.new, save_file_method: :madcat
    assert source.save_file('lol') == 'lol'
  end

  def test_name_custom_method
    source = S3DataPacker::Targets::Object.new object: TestTarget.new, name_method: :bobcat
    assert source.name == "I'm a test LOL"
  end
end
