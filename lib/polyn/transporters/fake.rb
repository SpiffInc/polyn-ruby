# frozen_string_literal: true

require_relative "base"

module Polyn
  module Transporters
    ##
    # Fake transporter for use in testing
    class Fake < Base
      def initialize(options = {})
        super(options)
        @subscriptions = []
      end

      def connect
        logger.info("connected")
        true
      end

      def disconnect
        logger.info("disconnected")
        true
      end

      def publish(topic, message)
        subscriptions[topic]&.each { |block| block.call(message) }
      end

      def subscribe(topic, &block)
        subscriptions[topic] ||= []
        subscriptions[topic] << block
      end

      private

      attr_reader :subscriptions
    end
  end
end
