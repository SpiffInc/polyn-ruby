# frozen_string_literal: true

require "json"
require "json_schemer"

module Polyn
  ##
  # Persisting and interacting with persisted schemas
  class SchemaStore
    STORE_NAME = "POLYN_SCHEMAS"

    ##
    # Persist a schema. In prod/dev schemas should have already been persisted via
    # the Polyn CLI.
    def self.save(nats, type, schema, **opts)
      json_schema?(schema)
      kv = nats.jetstream.key_value(store_name(opts))
      kv.put(type, JSON.generate(schema))
    end

    def self.json_schema?(schema)
      JSONSchemer.schema(schema)
    end

    def self.store_name(**opts)
      opts.fetch(:name, STORE_NAME)
    end
  end
end
