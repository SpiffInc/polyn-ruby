# frozen_string_literal: true

require "digest/sha1"

module Polyn
  ##
  # Test helpers to help keep tests predictable
  class Testing
    def self.setup
      RSpec.shared_context :polyn do
        let(:nats) { NATS.connect }
        let(:js) { nats.jetstream }

        before(:each) do |example|
          add_test_stream(example_hash(example))
        end

        after(:each) do |example|
          delete_test_stream(example_hash(example))
        end

        def add_test_stream(name)
          js.add_stream(name: name, subjects: ["#{name}.>"])
        end

        def delete_test_stream(name)
          js.delete_stream(name)
        end

        def example_hash(example)
          stream_name_from_description(example.metadata[:full_description])
        end

        def stream_name_from_description(description)
          hash = Digest::MD5.hexdigest(description)
          hash[0..20]
        end
      end
    end
  end
end
