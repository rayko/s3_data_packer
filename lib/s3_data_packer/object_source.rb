module S3DataPacker
  class ObjectSource

    def initialize(object:, each_method: :each, fetch_method: :fetch, name_method: :name)
      @object = object
      @each_method = each_method
      @fetch_method = fetch_method
      @name_method = name_method
    end

    def name
      @object.send(@name_method).to_s
    end

    def each &block
      @object.send(@each_method) do |item|
        yield item
      end
    end

    def fetch(item)
      @object.send(@fetch_method, item)
    end

  end
end
