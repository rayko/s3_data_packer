
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "s3_data_packer/version"

Gem::Specification.new do |spec|
  spec.name          = "s3_data_packer"
  spec.version       = S3DataPacker::VERSION
  spec.authors       = ["Rayko"]
  spec.email         = ["rayko.drg@gmail.com"]

  spec.summary       = "Simple file processor for packing data from S3."
  spec.description   = "This tool will read files from S3 by a prefix, and combine the files into batch-like files."
  spec.homepage      = "https://github.com/rayko/s3_data_packer"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/rayko/s3_data_packer"
    spec.metadata["changelog_uri"] = "https://github.com/rayko/s3_data_packer/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "byebug"

  spec.add_dependency 'aws-sdk-s3', '~> 1'
  spec.add_dependency 'mime-types', '~> 3'
end
