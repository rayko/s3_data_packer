module S3DataPacker
  class ThreadSet
    attr_reader :lock, :workers, :queue

    def initialize opts ={}
      @lock = Mutex.new
      @workers = []
      @finish = false
      @queue = S3DataPacker::Queue.new
    end

    def wait_time
      @wait_time ||= S3DataPacker.config.thread_sleep_time
    end

    def lock_wait_time
      @lock_wait_time ||= S3DataPacker.config.thread_lock_wait_time
    end

    def thread_count
      @thread_count ||= S3DataPacker.config.thread_count
    end

    def dead?
      workers.map(&:status).uniq == [nil] || workers.map(&:status).uniq == [false]
    end

    def kill!
      log 'All', "Killing #{workers.size} workers"
      workers.map(&:kill)
    end

    def reset!
      return unless dead?
      @finish = false
      @workers = []
    end

    def finish!
      @finish = true
    end

    def finished?
      @finish == true && queue.size == 0
    end

    def log id, message, level = :info
      logger.send level, "Thread #{id}: #{message}"
    end

    def wait!
      workers.map(&:join)
    end

    def spawn_thread! id, &block
      @workers << Thread.new do
        log id, "Started!"
        loop do
          if finished?
            log id, "Finish signal up and no more work to pull - Exiting"
            break
          end
          item = queue.fetch!
          if item
            log id, "Processing item #{item}", :debug
            begin
              yield item
            rescue ThreadError
              log id, "Locked, retry in #{lock_wait_time}", :warn
              sleep(lock_wait_time)
              retry
            end
          else
            log id, "No more work found, sleeping for #{wait_time}"
            sleep(wait_time)
          end
        rescue Exception => e
          log id, 'Unexpected error!'
          raise e
        end
      end
    end

    def spawn_threads! &block
      logger.info "Spawning #{thread_count} threads"
      thread_count.times do |id|
        spawn_thread!(id, &block)
      end
    end

    private

    def logger
      @logger ||= S3DataPacker.logger
    end

  end
end
