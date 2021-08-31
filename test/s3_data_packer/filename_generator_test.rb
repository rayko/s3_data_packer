require 'test_helper'

class FilenameGeneratorTest < Minitest::Test
  def setup
    @generator = S3DataPacker::FilenameGenerator.new
  end

  def test_methods
    assert_respond_to @generator, :pattern
    assert_respond_to @generator, :number
    assert_respond_to @generator, :splitter
    assert_respond_to @generator, :timecode_int
    assert_respond_to @generator, :timecode_dec
    assert_respond_to @generator, :timestamp
    assert_respond_to @generator, :datestamp
    assert_respond_to @generator, :prefix
    assert_respond_to @generator, :suffix
    assert_respond_to @generator, :generate!
  end

  def test_defaults
    assert_equal @generator.number, 1
    assert_nil @generator.prefix, S3DataPacker.config.output_filename_prefix
    assert_equal @generator.suffix, S3DataPacker.config.output_filename_suffix
    assert_equal @generator.splitter, S3DataPacker.config.output_filename_splitter
    assert_equal @generator.pattern, S3DataPacker.config.output_filename_pattern
  end

  def test_generate!
    gen = S3DataPacker::FilenameGenerator.new pattern: [:timecode_dec, :suffix]
    name = nil
    3.times do
      new_name = gen.generate!
      refute_equal name, new_name
      name = new_name
    end
  end

  def test_timecode_int
    number = @generator.timecode_int
    assert_kind_of Integer, number
    assert (Time.now.to_i - 1) < number
    assert number < (Time.now.to_i + 1)
  end

  def test_timecode_dec
    number = @generator.timecode_dec
    assert_kind_of Float, number
    assert number < Time.now.to_f
  end

  def test_number
    assert_equal @generator.number, 1
    @generator.generate!
    assert_equal @generator.number, 2
    @generator.generate!
    assert_equal @generator.number, 3
  end

  # This might sometimes fail if run at the right time
  def test_timestamp
    stamp = Time.now.strftime('%Y%m%d%H%M%s')
    assert_equal stamp, @generator.timestamp
  end

  # This might also fail is running near date change at midnight
  def test_datestamp
    stamp = Time.now.strftime('%Y%m%d')
    assert_equal stamp, @generator.datestamp
  end

  def test_prefix
    gen = S3DataPacker::FilenameGenerator.new prefix: 'lolcat', pattern: %i[prefix timecode_int suffix]
    assert gen.generate!.include?('lolcat_')
  end

  def test_suffix
    gen = S3DataPacker::FilenameGenerator.new suffix: 'lolcat', pattern: %i[prefix timecode_int suffix]
    assert gen.generate!.include?('_lolcat')
  end

  def test_splitter
    gen = S3DataPacker::FilenameGenerator.new splitter: '-'
    assert_equal gen.generate!.split('-').size, 2
  end

  def test_invalid_pattern_key
    assert_raises(ArgumentError) { S3DataPacker::FilenameGenerator.new(pattern: %i[lolcat]) }
  end

  def test_invalid_pattern_key_type
    assert_raises(ArgumentError) { S3DataPacker::FilenameGenerator.new(pattern: %w[prefix]) }
  end

end
