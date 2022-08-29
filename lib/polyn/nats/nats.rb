# frozen_string_literal: true

module Polyn
  ##
  # Adapter/wrapper around Nats
  class Nats
    def initialize(nats)
      @nats = nats
    end

    def publish(type, json, reply, **opts)
      @nats.publish(type, json, reply, **opts)
    end

    def subscribe(type, opts = {}, &callback)
      @nats.subscribe(type, opts) { |msg| callback.call(msg) }
    end

    def jetstream
      @jetstream ||= Polyn::JetStream.new(@nats.jetstream)
    end
  end
end
