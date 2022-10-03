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
      @type          = Polyn::Naming.trim_domain_prefix(fields.fetch(:type))
      @consumer_name = Polyn::Naming.consumer_name(@type, fields[:source])
      @stream        = @nats.jetstream.find_stream_name_by_subject(@type)
      self.class.validate_consumer_exists!(@nats, @stream, @consumer_name)
      @psub          = @nats.jetstream.pull_subscribe(@type, @consumer_name)
      @serializer    = fields.fetch(:serializer)
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
      Polyn::Tracing.processing_span(@type) do |process_span|
        msgs = @psub.fetch(batch, params)
        msgs.map do |msg|
          Polyn::Tracing.subscribe_span(@type, msg, links: [process_span]) do |span|
            updated_msg = process_message(msg)
            Polyn::Tracing.span_attributes(span,
              nats:    @nats,
              type:    @type,
              event:   updated_msg.data,
              payload: msg.data)
            updated_msg
          end
        end
      end
    end

    private

    def process_message(msg)
      msg   = msg.clone
      msg   = Polyn::Nats::Msg.new(msg)
      event = @serializer.deserialize(msg.data)
      if event.is_a?(Polyn::Errors::Error)
        msg.term
        raise event
      end

      msg.data = event
      msg
    end
  end
end
