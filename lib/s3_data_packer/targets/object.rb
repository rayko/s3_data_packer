module S3DataPacker
  module Targets
    class Object

      def initialize(object:, name_method: :each, save_file_method: :save_file)
        @object = object
        @name_method = name_method
        @save_file_method = save_file_method
      end

      def name
        @object.send(@name_method)
      end

      def save_file(filepath)
        @object.send(@save_file_method, filepath)
      end

    end
  end
end
