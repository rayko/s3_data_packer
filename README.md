# S3DataPacker

This small packer will read a large amount of individual files on an S3 location that represent single
items in JSON format, and pack them into larget batches with the option of compressing the final batch,
decreasing the total storage size of the data (if compressed), and also reducing the total number of files.

The idea is to prepare data dumped on S3 in this way to a more optimal layout for AWS Athena to setup
a querying system on top of it.

For now, S3DataPacker supports JSON items, with a 1 item per file layout, GZip compression if enabled, and
only from S3 to S3, though the source and target bucket can be different buckets or even on different accounts
if the proper credentials are provided.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3_data_packer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_data_packer

## Configurations

There's a good number of options that can alter how the data is consumed. Below is the list of all defaults
out of the box:

```
S3DataPacker.configure do |config|
  config.logger = Logger.new('log/s3_data_packer.log')     # Standard logger for information
  config.thread_count = 2                                  # How many threads to run
  config.thread_sleep_time = 1                             # How long to wait when there's no work in queue
  config.thread_lock_wait_time = 1                         # How long to wait when a lock error happens before retrying
  config.max_queue_size = 10000                            # How big can the queue get during processing
  config.max_queue_wait = 5                                # How long to wait when the queue reached max_queue_size before continuing
  config.workdir = 'tmp/s3_data_packer'                    # Where to keep output files until pushing to target location
  config.cleanup_batch = true                              # Whether to remove the pushed batches or not
  config.compress_batch = true                             # Whether to compresss with GZip or not
  config.batch_size = 100000                               # How many items to fit in a batch
  config.s3_api_key = nil                                  # Default API Key for an Aws account
  config.s3_api_secret = nil                               # Default API Secret for an AWS account
  config.s3_region = nil                                   # Default region for the buckets to use
  config.output_filename_prefix = nil                      # Static prefix to append on output filenames
  config.output_filename_suffix = 'batch'                  # Static suffix to insert on output filenames
  config.output_filename_pattern = %i[timecode_int suffix] # Simple pattern to construct output filenames (more on that below)
  config.output_filename_splitter = '_'                    # Character to join elements into a string that'll be a final filename
end
```

### S3 Credentials

There are 2 main ways to do this depending on the context. Buckets can be configured in place with user provided
credentials for both source and target locations.

If the source and target locations are on the same account, region and use the same credentials, the options
above can be set to always set those credentials.

AWS credentials in the configuration here are optional, and just a shortcut to setting credentials for each
run.

### Thread options

Various thread options are available to moderate how the process run. Depending on the hardware available
the thread counts can be adjusted to speed up the process. However, it there are enough threads, the queue
might run empty too soon, in which case threads will sleep the given ammount of time to wait to gather
some items to work on.

All timming settings should be adjusted depending on where this is going to run and the resources available.

### Output filename options

There are a couple parameters that can be configured generally to generate filenames consistently. The simplest
options `:output_filename_prefix`, `:output_filename_suffix` and `:output_filename_splitter` are straight 
forward. The `:output_filename_pattern` option is a bit more involved. It basically dictates order and what 
values to use when generating a filename. When a new name needs to be generated, each item in the pattern will 
be translated to a value of some kind, and merged toghether with the `:output_filename_splitter` character. 
The contents of the pattern array must be `Symbol` names and can only be one of the following:

- :timecode_int -> current standard time in seconds (`Time.now.to_i`)
- :timecode_dec -> current standard time with milliseconds (`Time.now.to_f`)
- :number -> a simple number that grows as new names are generated
- :timestamp -> simple time stamp with format YYYYMMDDhhmmss
- :datestamp -> simple date stamp with format YYYYMMDD
- :prefix -> given static string to use as prefix on the name
- :suffix -> given static string to use as suffix on the name

Different patterns will generate different names with same structuring. The important part here is to always
include a variable element so final files do not override previous data.

A few examples of different patterns, setting prefix as 'data' and suffix as 'batch':

- [:timecode_int, :suffix] -> 1111111111_batch 1111111112_batch 1111111113_batch ...
- [:datestamp, :number] -> 20200101_1 20200101_2 20200101_3 ...
- [:prefix, :number, :suffix] -> data_1_batch data_2_batch data_3_batch ...

## Usage

The simplest setup for this simple file processor is to set the AWS credentials and region through the
configuration as shown above. Be sure that `config.workdir` is set and the location exists in the local
machine.

To launch the packer, the only thing needed out of the box, is to instantiate 2 `S3DataPacker::Bucket`
objects that will act as source and destination:

```
source_bucket = S3DataPacker::Bucket.new name: 'my-bucket', path: 'some/location'
target_bucket = S3DataPacker::Bucket.new name: 'other-bucket', path: 'my/destination'
```

You can override the configured AWS credentials with the `:credentials` option, as well as `:region`.
`:credentials` needs to be an instance of `Aws::Credentials`. Having it setup this way should allow
for more complex role invoking, since the instance passed `:credentials` option is fed direclty to
`Aws::S3::Resource` and `Aws::S3::Client` to interface with the S3 buckets.

Once the buckets are instantiated you can call the packer:

```
packer = S3DataPacker::Packer.new source: source_bucket, target: target_bucket
packer.pack!
```

### How it works?

Based on the sample above, what will happen once that `#pack!` is called, is that a set of threads will boot
up, a new file will be opened in `config.workdir` that, without further configuration it will be named
`123123123_batch.json` (in general), and then the packer will start to iterate over all keys under the 
source path `some/location`.

Each key listed will enter the queue for the threads, and the threads will then take each key in queue,
download the data in memory (it does not create a file for it), append the data into the currently opened
batch, and continue with the next key.

As items are appended, if the target size `config.batch_size` is reached, the current batch is closed,
compressed with GZip, and uploaded to target bucket in the location specificed `my/destination`. Once
the file is pushed, the local copy is deleted, and a new batch is opened to continue appending items.

When all the keys have been listed, the packer will wait for the threads to finish any remaining items in the
queue, and the last opened batch that likely hasn't reached target size, is then closed and pushed like the
others.

And that's basically it. There are a few places in where additional processing may be introduced, but that's
a feature for later.

There are no specialties regarding source and target buckets, they can be the same, on different accounts
or region. However it is not recommended to setup source and target on the same bucket and path.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rayko/s3_data_packer. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to 
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the S3DataPacker project’s codebases, issue trackers, chat rooms and mailing lists 
is expected to follow the [code of conduct](https://github.com/[USERNAME]/s3_data_packer/blob/master/CODE_OF_CONDUCT.md).
