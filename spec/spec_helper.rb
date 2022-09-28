# frozen_string_literal: true

require "polyn"
require "simplecov"
require "timecop"
require "opentelemetry/sdk"

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

Polyn.configure do |config|
  config.domain      = "com.test"
  config.source_root = "user.backend"
end

# Setup the test-only SDK for OpenTelemetry to capture spans. The Exporter is what
# will actually record the spans and allow us to access them
EXPORTER       = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
