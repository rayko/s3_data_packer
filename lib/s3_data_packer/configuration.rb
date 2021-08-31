module S3DataPacker
  class Configuration
    # Standard logger to output information
    attr_accessor :logger

    # How many threads to run for reading and processing items. This needs to be
    # balanced out with the speed at which item keys are gathered to prevent
    # emptying the queue too early.
    attr_accessor :thread_count

    # Time in seconds to let a thread sleep when there's no pending items in queue.
    attr_accessor :thread_sleep_time

    # Time in seconds for thread to wait when locked.
    attr_accessor :thread_lock_wait_time

    # Maximum number of items to maintain in queue to not overflow while workers
    # process items.
    attr_accessor :max_queue_size

    # Time in seconds to wait when the queue reached max_queue_size to keep adding
    # new items.
    attr_accessor :max_queue_wait

    # Directory to keep working files. Make sure you have permissions on the path
    # set. If the path does not exist, the packer will try to create it before using
    # it.
    attr_accessor :workdir

    # Whether to keep or delete the finalized batch file. Set to false if you want to
    # keep the output files in the workdir.
    attr_accessor :cleanup_batch

    # Whether to compress the final batch file or not. If set to true, the output file
    # will be compressed with GZip, and the uncompressed file will be removed.
    attr_accessor :compress_batch

    # Number of items of the final batch size
    attr_accessor :batch_size

    attr_accessor :s3_api_key
    attr_accessor :s3_api_secret
    attr_accessor :s3_region

    # String prefix to include in output filenames for the batches
    attr_accessor :output_filename_prefix

    # String suffix to include in output filenames for the batches
    attr_accessor :output_filename_suffix

    # Desired pattern to construct output filenames
    attr_accessor :output_filename_pattern

    # Splitter character to concat different values to generate a filename
    attr_accessor :output_filename_splitter

    def initialize
      @thread_count = 2
      @thread_sleep_time = 1
      @thread_lock_wait_time = 1
      @max_queue_size = 10000
      @max_queue_wait = 5
      @batch_size = 100000
      @workdir = 'tmp/s3_data_packer'
      @cleanup_batch = true
      @compress_batch = true
      @output_filename_suffix = 'batch'
      @output_filename_pattern = %i[timecode_int suffix]
      @output_filename_splitter = '_'
    end

    def compress_batch?
      compress_batch == true
    end

    def cleanup_batch?
      cleanup_batch == true
    end

    def s3_credentials?
      s3_api_key && s3_api_secret
    end

    def default_s3_credentials
      return nil unless s3_credentials?

      Aws::Credentials.new(s3_api_key, s3_api_secret)
    end

    def filename_generator_defaults
      { prefix: output_filename_prefix,
        suffix: output_filename_suffix,
        pattern: output_filename_pattern,
        splitter: output_filename_splitter }
    end

  end
end
