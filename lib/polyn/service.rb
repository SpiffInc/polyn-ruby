# frozen_string_literal: true

module Polyn
  ##
  # A service is an event handler on the Polyn event bus.
  class Service
    ##
    # List of invalid event handlers
    INVALID_EVENT_HANDLERS = %i[transporter].freeze

    class << self
      ##
      # @return [Hash] the events defined in the service
      attr_reader :events

      ##
      # Defines an event handler for a service for the specified topic
      #
      # @param topic [String|Regexp] the topic to listen on
      # @param method [Symbol] the method to call when the event is received
      def event(topic, method)
        @events      ||= {}
        validate(topic, method)
        @events[topic] = method
      end

      ##
      # Validates the event handler
      #
      # @private
      def validate(topic, _method)
        validate_topic(topic)
      end

      ##
      # Validates the topic
      def validate_topic(topic)
        return unless topic.is_a?(String) || topic.is_a?(Regexp)

        raise ArgumentError,
              "Topic must be a String or Regexp"
      end
    end

    ##
    # @param transporter [Poly::Transporter] the transporter to use for sending events
    def initialize(transporter:)
      @transporter = transporter
    end

    private

    attr_reader :transporter
  end
end
