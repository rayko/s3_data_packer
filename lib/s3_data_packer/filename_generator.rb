module S3DataPacker
 class FilenameGenerator
   attr_reader :pattern, :number, :splitter

   def initialize opts={}
     @number = opts[:start_at] || 1
     @prefix = opts[:prefix] || default_options[:prefix]
     @suffix = opts[:suffix] || default_options[:suffix]
     @pattern = opts[:pattern] || default_options[:pattern]
     @splitter = opts[:splitter] || default_options[:splitter]
     validate_pattern!
   end

   def timecode_int; Time.now.to_i.to_s; end
   def timecode_dec; Time.now.to_f.to_s; end
   def number; @number.to_s; end
   def timestamp; Time.now.strftime('%Y%m%d%H%M%s'); end
   def datestamp; Time.now.strftime('%Y%m%d'); end
   def prefix; @prefix.to_s; end
   def suffix; @suffix.to_s; end

   def generate!
     name = pattern.map{ |key| send(key) }
     name.delete_if { |value| value.nil? || value == '' }
     name = name.join(splitter)
     @number += 1
     name
   end

   private

   def default_options
     @default_options ||= S3DataPacker.config.filename_generator_defaults
   end

   def validate_pattern!
     valid = %i[timecode_int timecode_dec number timestamp datestamp prefix suffix]
     pattern.each do |item|
       raise ArgumentError, "Invalid pattern key, has to be a symbol" unless Symbol === item
       raise ArgumentError, "Invalid pattern key #{item}. Allowed: #{valid.join(', ')}" unless valid.include?(item)
     end
   end
     
 end
end
