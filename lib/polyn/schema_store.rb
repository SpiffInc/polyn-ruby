# frozen_string_literal: true

module Polyn
  ##
  # Persisting and interacting with persisted schemas
  class SchemaStore
    STORE_NAME = "POLYN_SCHEMAS"

    ##
    # Persist a schema. In prod/dev schemas should have already been persisted via
    # the Polyn CLI.
    def self.save(nats, type, schema, **opts)
      kv = nats.jetstream.key_value(store_name(opts))
      kv.put(type, schema)
      # is_json_schema?(schema)
      # KV.create_key(conn, store_name(opts), type, encode(schema))
    end

    def self.store_name(**opts)
      opts.fetch(:name, STORE_NAME)
    end
  end
end
