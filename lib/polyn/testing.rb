# frozen_string_literal: true

require "polyn/schema_store"
require "polyn/testing/mock_nats"

module Polyn
  ##
  # Test helpers to help keep tests predictable
  class Testing
    ##
    # Use this in spec_helper.rb to include a shared_context that can be
    # used with `include_context :polyn`
    def self.setup(**_opts)
      conn         = NATS.connect
      schema_store = Polyn::SchemaStore.new(conn)

      RSpec.shared_context :polyn do
        before(:each) do
          # Add reusable instances to the running thread so that
          # application-level Polyn instantiations can use them when
          # in a test environment
          Thread.current[:polyn_schema_store] = schema_store
        end

        after(:each) do
          Thread.current[:polyn_schema_store] = nil
        end
      end
    end
  end
end
