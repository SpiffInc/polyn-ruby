# frozen_string_literal: true

module Polyn
  ##
  # Persisting and interacting with persisted schemas
  class SchemaStore
    STORE_NAME   = "POLYN_SCHEMAS"

    def initialize(nats, **opts)
      @nats       = nats
      @store_name = opts[:name] || STORE_NAME
      @key_prefix = "$KV.#{@store_name}"
      @schemas    = opts[:schemas] || fetch_schemas
    end

    attr_reader :schemas

    ##
    # Persist a schema. In prod/dev schemas should have already been persisted via
    # the Polyn CLI.
    def save(type, schema)
      json_schema?(schema)
      schemas[type] = JSON.generate(schema)
    end

    def json_schema?(schema)
      JSONSchemer.schema(schema)
    end

    def get!(type)
      result = get(type)
      raise result if result.is_a?(Polyn::Errors::SchemaError)

      result
    end

    def get(type)
      schema = schemas[type]

      if schema.nil?
        return Polyn::Errors::SchemaError.new(
            "Schema for #{type} does not exist. Make sure it's "\
            "been added to your `events` codebase and has been loaded "\
            "into the schema store on your NATS server",
          )
      end

      schema
    end

    private

    def fetch_schemas
      loop_store_keys
    rescue NATS::JetStream::Error::NotFound
      raise Polyn::Errors::SchemaError, "The Schema Store #{@store_name} has "\
        "not been setup on your NATS server. Make sure you use Polyn CLI to create it"
    end

    def loop_store_keys
      sub            = @nats.jetstream.subscribe("#{@key_prefix}.>")
      results        = {}

      loop do
        msg                                              = sub.next_msg
        results[msg.subject.gsub("#{@key_prefix}.", "")] = msg.data unless msg.data.empty?
      # A timeout is the only mechanism given to indicate there are no
      # more messages
      rescue NATS::IO::Timeout
        break
      end

      sub.unsubscribe
      results
    end
  end
end
