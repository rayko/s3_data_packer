module S3DataPacker
  class Queue
    attr_reader :total_items, :items

    def initialize opts = {}
      @max_items = opts[:max_items]
      @wait_time = opts[:wait_time]
      @total_items = 0
    end

    def max_items
      @max_items ||= S3DataPacker.config.max_queue_size
    end

    def wait_time
      @wait_time ||= S3DataPacker.config.max_queue_wait
    end

    def items
      @items ||= []
    end

    def add!(item)
      items << item
      @total_items += 1
      if size >= max_items
        S3DataPacker.logger.info "Queue full, pausing"
        sleep(wait_time)
        S3DataPacker.logger.info "Resuming queue"
      end
    end

    def fetch!
      items.shift
    end

    def size
      items.size
    end

    def reset!
      @items = []
      @total_items = 0
    end
  end
end
