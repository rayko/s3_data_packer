module S3DataPacker
  class JSONBatch
    attr_reader :delimitter, :batch, :item_count

    def initialize opts = {}
      @delimitter = "\r\n"
      @workdir = opts[:workdir]
      @filename_generator = opts[:filename_generator]
      @pre_processor = opts[:pre_processor] # Should be a proc
      @size = opts[:size]
      @item_count = 0
      init_workdir!
    end

    def size
      @size ||= S3DataPacker.config.batch_size
    end

    def workdir
      @workdir ||= S3DataPacker.config.workdir
    end

    def filename_generator
      @filename_generator ||= S3DataPacker::FilenameGenerator.new
    end

    def full?
      item_count >= size
    end

    def generate_filename
      name = filename_generator.generate!
      "#{workdir}/#{name}.json"
    end

    def new_file!
      close! if @batch
      @batch = File.open(generate_filename, 'w')
    end

    def append_data! data
      digested = pre_proccess_data(data)
      batch << "#{digested}#{delimitter}"
      @item_count += 1
    end

    def path
      batch.path
    end

    def close!
      batch.close
    end

    def delete!
      close! if !@batch.closed?
      File.delete(path) if File.exist?(path)
      reset!
    end

    def finalize!
      close! if !batch.closed?
      final_path = batch.path
      final_path = compress! if S3DataPacker.config.compress_batch?
      reset!
      final_path
    end

    private

    def pre_proccess_data(raw_data)
      # Transformations here, return string for this one
      return @pre_processor.call(raw_data) if @pre_processor
      raw_data
    end

    def init_workdir!
      Dir.mkdir(workdir) unless Dir.exist?(workdir)
    end

    def compress!
      new_path = "#{batch.path}.gz"
      `gzip #{batch.path}`
      new_path
    end

    def reset!
      @batch = nil
      @item_count = 0
    end

  end
end
