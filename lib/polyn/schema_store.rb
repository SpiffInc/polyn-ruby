# frozen_string_literal: true

require "json"
require "json_schemer"
require "polyn/errors/schema_error"

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

    def self.get(nats, type, **opts)
      kv    = nats.jetstream.key_value(store_name(opts))
      entry = kv.get(type)
      entry.value
    rescue NATS::KeyValue::BucketNotFoundError
      raise Polyn::Errors::SchemaError,
        "The Schema Store has not been setup on your NATS server. Make sure you use the Polyn CLI to create it"
    end

    def self.store_name(**opts)
      opts.fetch(:name, STORE_NAME)
    end
  end
end
