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

Or use the `main` branch from repo:

```ruby
gem 's3_data_packer', git: 'https://github.com/rayko/s3_data_packer.git', branch: 'main'
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
source_bucket = S3DataPacker::Sources::S3Bucket.new name: 'my-bucket', path: 'some/location'
target_bucket = S3DataPacker::Sources::S3Bucket.new name: 'other-bucket', path: 'my/destination'
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

### Custom Sources/Targets

It is possible to define a custom source and target for the packer to read data from some different place
that is not an S3 bucket, as well as put the resultant batch into somewhere else. The `S3DataPacker::Packer`
can take `:source` and `:target` parameters to use other things. At the moment, there are 2 source classes
provided:

- `S3DataPacker::Sources::S3Bucket`
- `S3DataPacker::Sources::Object`

And 1 pre-defined target:

- `S3DataPacker::Targets::S3Bucket`

Both bucket related classes operate in the same way, you need to define the name and path of the buckets
to read and write the data, as in the main example above.

The object source is pretty much a wrapper you can use with some other custom object, passing down which
methods to call on it for the packer. Any object you pass down in the object source needs to respond to:

- `#name`: which is mostly used for logging
- `#each`: with a block to iterate over items
- `#fetch`: with an identifier to find the actual data of the item

The `#each` and `#fetch` methods are like that mainly because the packer is threaded and it expects to
iterate over keys, or IDs or some minor piece of information in one thread, and use that information
to retrive the full object data on other threads. This keeps the queue small in byte size.

By default the object source expects those method names to be defined in the object provided. If there
are other methods that do that already on the object but with different name, the method names can be
passed like so:

```ruby
S3DataPacker::Sources::Object.new object: my_object, 
                                  each_method: :iterate, 
                                  fetch_method: :find, 
                                  name_method: :display_name
```

As long as `#each` yields items (strings, IDs, whatever), and `#fetch` returns JSON data with for an item,
this should work.

For targets, there's also a `S3DataPacker::Targets::Object` that can be used in the a similar way, the only
2 methods for it are: 

- `#name`: for the same purposes as sources `#name` method
- `#save_file`: with a path parameter

It can also be configured with other method names if needed:

```ruby
S3DataPacker::Targets::Object.new object: my_object,
                                  name_method: :custom_name,
                                  save_file_method: :save!
```

It is also possible to construct a custom source/target class outside of the pre-defined ones that can
do anything needed, and passed down to the packer instance to use. As long as few needed methods are
there, it should work just fine.

In some cases it might be useful to unify the get/fetch mechanics. This can be easily done by just
bypassing the `#fetch` method and returning the data received. If for some reason the iterator for
`#each` needs to output the actual data right there, by writing a `#fetch` method that returns whatever
was passed in the parameter, effectively makes the packer's queue hold actual data. This might be useful
in some cases, though it might need a smaller max size configuration to prevent having too much data in the
queue.

I believe that with these tools, the packer can pretty much do the JSON packing in most cases, including:

- Reading database records and serializing them into JSON
- Reading S3 buckets (as originally intended)
- Reading NoSQL items
- Reading one file or a set of files
- Writing batches into S3 buckets (as originally intended)
- Writing batches into filesystem on some custom location
- Writing batches into some other custom location

At least, it does cover the cases in where I intend to use it.

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
