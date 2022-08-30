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
      json_schema?(schema)
      kv = nats.jetstream.key_value(store_name(**opts))
      kv.put(type, JSON.generate(schema))
    end

    def self.json_schema?(schema)
      JSONSchemer.schema(schema)
    end

    def self.get!(nats, type, **opts)
      result = get(nats, type, **opts)
      raise result if result.is_a?(Polyn::Errors::SchemaError)

      result
    end

    def self.get(nats, type, **opts)
      kv    = nats.jetstream.key_value(store_name(**opts))
      entry = kv.get(type)
      entry.value
    rescue NATS::KeyValue::BucketNotFoundError
      Polyn::Errors::SchemaError.new(
        "The Schema Store has not been setup on your NATS server. Make sure you use "\
        "the Polyn CLI to create it",
      )
    rescue NATS::JetStream::Error::NotFound
      Polyn::Errors::SchemaError.new(
        "Schema for #{type} does not exist. Make sure it's "\
        "been added to your `events` codebase and has been loaded "\
        "into the schema store on your NATS server",
      )
    end

    def self.all_schemas!(nats, **opts)
      subject_prefix = key_prefix(**opts)
      sub            = nats.jetstream.subscribe("#{subject_prefix}.>")
      schemas        = {}

      loop do
        msg                                                 = sub.next_msg
        schemas[msg.subject.gsub("#{subject_prefix}.", "")] = msg.data unless msg.data.empty?
      # A timeout is the only mechanism given to indicate there are no
      # more messages
      rescue NATS::IO::Timeout
        break
      end
      sub.unsubscribe
      schemas
    end

    def self.store_name(**opts)
      opts.fetch(:name, STORE_NAME)
    end

    def self.key_prefix(**opts)
      "$KV.#{store_name(**opts)}"
    end
  end
end
