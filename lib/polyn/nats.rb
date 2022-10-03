# frozen_string_literal: true

module Polyn
  ##
  # Adapter/wrapper around Nats
  class Nats
    def initialize(nats)
      @nats = nats
    end

    attr_reader :nats

    def publish(type, json, reply, **opts)
      @nats.publish(type, json, reply, **opts)
    end

    def subscribe(type, opts = {}, &callback)
      @nats.subscribe(type, opts) { |msg| callback.call(Polyn::Nats::Msg.new(msg)) }
    end

    def jetstream
      @jetstream ||= @nats.jetstream
    end
  end
end
