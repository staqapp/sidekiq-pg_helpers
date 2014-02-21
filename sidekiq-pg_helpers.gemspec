# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/pg_helpers/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-pg_helpers"
  spec.version       = Sidekiq::PgHelpers::VERSION
  spec.authors       = ["Mike Subelsky"]
  spec.email         = ["github@mikeshop.net"]
  spec.summary       = %q{Helper code for using Sidekiq with Postgres. Extracted from our production code.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/staqapp/sidekiq-pg_helpers"
  spec.license       = "MIT"
  spec.date          = "2014-02-21"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "pg"
  spec.add_runtime_dependency "activerecord"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
