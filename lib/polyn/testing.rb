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
          # Have a global, shared schema store that only pulls the schemas
          # once for the whole test suite. For testing an application the
          # schemas are expected to be the same throughout the whole suite
          Thread.current[:polyn_schema_store] = schema_store
        end

        after(:each) do
          Thread.current[:polyn_schema_store] = nil
        end
      end
    end
  end
end
