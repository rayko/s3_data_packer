# S3DataPacker

This little tool aims to process a large amount of individual tiny files stored in some S3 bucket,
in order to combine them into larger batches that are more managable for a variety of purposes.

Combining these small raw files into bigger ones enables some optimizations if you re upload these
packed files to S3, like compressing these batches to save space, prepare data for other services
like AWS Athena, implement life cycle policies that didn't work on tiny files, and overall have
more managable items to work with for cataloguing, or other processes. Simply put, it will be easier
to download one big file at a time and process its contents than download millions of tiny files
for the same purpose.

The idea behind this tool was mainly a way to prepare and optimize data to better work with Athena
and keep costs of operation low.

For now, the tool just packs JSON files, splitted by CRLB characters, compressing the results with
GZip.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3_data_packer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_data_packer

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/s3_data_packer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the S3DataPacker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/s3_data_packer/blob/master/CODE_OF_CONDUCT.md).
