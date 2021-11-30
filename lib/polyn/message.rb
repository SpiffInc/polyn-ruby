# frozen_string_literal: true

require "securerandom"

module Polyn
  ##
  # Represents a Polyn message.
  class Message
    def initialize(topic:, origin:, payload:, parent: nil, service: nil)
      @topic      = topic
      @payload    = payload
      @service    = service
      @origin     = origin
      @trace      = []
      @created_at = Time.now.utc
      @uuid       = SecureRandom.uuid
    end

    def for_transit
      {
        topic:     topic,
        eventId:   uuid,
        origin:    origin,
        createdAt: created_at,
        client:    {
          type:    "ruby",
          version: Polyn::VERSION,
        },
        trace:     trace,
        payload:   payload,
      }
    end

    private

    attr_reader :topic, :payload, :service, :origin, :trace, :created_at, :uuid
  end
end
