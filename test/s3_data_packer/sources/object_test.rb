require 'test_helper'

class TestSource
  # This would be for the #each method
  def lolcat &block
    10.times { |n| yield n }
  end

  # This would be for the #fetch medhot
  def madcat(item)
    item * 10
  end

  # And this would be for the #name method
  def bobcat
    "I'm a test LOL"
  end
end

class ObjectTest < Minitest::Test
  def test_methods
    source = S3DataPacker::Sources::Object.new object: Object.new
    assert_respond_to source, :each
    assert_respond_to source, :fetch
    assert_respond_to source, :name
  end

  def test_each_custom_method
    source = S3DataPacker::Sources::Object.new object: TestSource.new, each_method: :lolcat
    source.each do |item|
      assert item != nil
    end
  end

  def test_name_custom_method
    source = S3DataPacker::Sources::Object.new object: TestSource.new, name_method: :bobcat
    assert source.name == "I'm a test LOL"
  end

  def test_fetch_custom_method
    source = S3DataPacker::Sources::Object.new object: TestSource.new, fetch_method: :madcat
    assert source.fetch(5) == 50
  end
end
