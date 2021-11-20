# frozen_string_literal: true

module Polyn
  module Transporters
    ##
    # The Base transporter defines the interface for all other transporters.
    # @abstract
    class Base < Concurrent::Actor::RestartingContext
      def initialize(options = {})
        @options = options
      end

      def connect
        raise NotImplementedError
      end

      def disconnect
        raise NotImplementedError
      end

      def publish(topic, message)
        raise NotImplementedError
      end

      def subscribe(topic, &block)
        raise NotImplementedError
      end

      private

      def default_executor
        Concurrent.global_io_executor
      end
    end
  end
end
