# frozen_string_literal: true

module Polyn
  ##
  # Wrapper around nats-pure that can validate polyn messages
  class PullSubscriber
    ##
    # @param fields [Object] :nats - Connected NATS instance from `NATS.connect`
    # @param fields [String] :type - The type of event
    # @option fields [String] :source - If the `source` portion of the consumer name
    # is more than the `source_root`
    def initialize(fields)
      @nats          = fields.fetch(:nats)
      @type          = fields.fetch(:type)
      @type          = Polyn::Naming.trim_domain_prefix(@type)
      @consumer_name = Polyn::Naming.consumer_name(@type, fields[:source])
      @stream        = @nats.jetstream.find_stream_name_by_subject(@type)
      self.class.validate_consumer_exists!(@nats, @stream, @consumer_name)
      @psub          = @nats.jetstream.pull_subscribe(@type, @consumer_name)
      @store_name    = store_name(fields)
    end

    # nats-pure will create a consumer if the one you passed does not exist.
    # Polyn wants to avoid this functionality and instead encourage
    # consumer creation in the centralized `events` codebase so that
    # it's documented, discoverable, and polyn-cli can manage it
    def self.validate_consumer_exists!(nats, stream, consumer_name)
      nats.jetstream.consumer_info(stream, consumer_name)
    rescue NATS::JetStream::Error::NotFound
      raise Polyn::Errors::ValidationError,
        "Consumer #{consumer_name} does not exist. Use polyn-cli to create"\
        "it before attempting to subscribe"
    end

    # fetch makes a request to be delivered more messages from a pull consumer.
    #
    # @param batch [Fixnum] Number of messages to pull from the stream.
    # @param params [Hash] Options to customize the fetch request.
    # @option params [Float] :timeout Duration of the fetch request before it expires.
    # @return [Array<NATS::Msg>]
    def fetch(batch = 1, params = {})
      msgs = @psub.fetch(batch, params)
      msgs.map do |msg|
        event    = Polyn::Serializers::Json.deserialize!(@nats, msg.data, store_name: @store_name)
        msg.data = event
        msg
      end
    end

    private

    def store_name(opts)
      opts.fetch(:store_name, Polyn::SchemaStore.store_name)
    end
  end
end
