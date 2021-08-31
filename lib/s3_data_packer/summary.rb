module S3DataPacker
  class Summary
    def stats
      @stats ||= {}
    end

    def count_item
      stats[:total_items] ||= 0
      stats[:total_items] += 1
    end

    def count_processed
      stats[:processed] ||= 0
      stats[:processed] += 1
    end

    def count_batch
      stats[:batches] ||= 0
      stats[:batches] += 1
    end

    def set_time start_time, end_time
      stats[:elapsed] = "#{(end_time.to_i - start_time.to_i)} seconds"
    end

    def total_items
      stats[:total_items] || 0
    end

    def processed
      stats[:processed] || 0
    end

    def batches
      stats[:batches] || 0
    end

    def elapsed
      stats[:elapsed]
    end

    def flush!
      output = [
        "Summary:",
        "Total Items: #{stats[:total_items]}",
        "Processed Items: #{stats[:processed]}",
        "Batches: #{stats[:batches]}",
        "Elapsed: #{stats[:elapsed]}"
      ].join("\n")
      reset!
      output
    end

    def reset!
      @stats = {}
    end

  end
end
