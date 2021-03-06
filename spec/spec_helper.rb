# frozen_string_literal: true

require "polyn"
require "simplecov"
require "timecop"

RSpec.configure do |config|
  SimpleCov.start

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
