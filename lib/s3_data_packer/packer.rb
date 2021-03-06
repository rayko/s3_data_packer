module S3DataPacker
  class Packer
    module Error
      class DeadWorkers < StandardError; end
    end

    attr_reader :source, :target, :output

    def initialize opts = {}
      @source = opts[:source]
      @target = opts[:target]
      @output = opts[:output] || S3DataPacker::JSONBatch.new
    end

    def summary
      @summary ||= S3DataPacker::Summary.new
    end

    def logger
      @logger ||= S3DataPacker.logger
    end

    def workers
      @workers ||= S3DataPacker::ThreadSet.new
    end

    def pack!
      log "Packing data from #{source.name} to #{target.name} ..."
      boot_workers!

      @start_time = Time.now
      begin
        each_item { |item| workers.queue.add!(item) }
        finalize_processing!
      rescue Exception => e
        log "Unexpected error, killing threads", :error
        raise e
      ensure
        workers.kill!
      end
    end

    def process_item(data)
      output.append_data! data
      summary.count_processed
      if output.full?
        flush_batch!
        output.new_file!
      end
    end

    private

    def finalize_processing!
      log "No more items found to enqueue, signaling workers to finish"
      workers.finish!
      workers.wait!
      workers.kill!
      log "Pushing last open batch #{output.path}"
      flush_batch!
      summary.set_time(@start_time, Time.now)
      log "Finished\n#{summary.flush!}"
    end

    def each_item &block
      source.each do |item|
        if workers.dead?
          log "Workers diead", :error
          raise Error::DeadWorkers, 'Workers died'
        end
        summary.count_item
        yield item
      end
    end

    def flush_batch!
      summary.count_batch
      final_filename = output.finalize!
      send_file!(final_filename)
    end

    def send_file!(file)
      target.save_file file
    end

    def boot_workers!
      output.new_file!
      workers.spawn_threads! do |item|
        data = source.fetch(item)
        workers.lock.synchronize { process_item(data) }
        post_process_item(item)
      end
    end

    def post_process_item(item)
      # Do something with the key after processed
      nil
    end

    def log(message, level = :info)
      logger.send level, "Main process: #{message}"
    end

  end
end
