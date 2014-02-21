require "rubygems"
require "bundler"

Bundler.setup(:default,:test)
require "rspec"
require "pp"
require "pry"

$:.unshift("#{__dir__}/../lib/staq_rendering")

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = "random"
end
