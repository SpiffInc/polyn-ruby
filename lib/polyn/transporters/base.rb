# frozen_string_literal: true

# Copyright 2021-2022 Spiff, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require_relative "./message"

module Polyn
  module Transporters
    ##
    # The Base transporter defines the interface for all other transporters.
    # @abstract
    class Base < Concurrent::Actor::RestartingContext
      include SemanticLogger::Loggable

      ##
      # @private
      class Wrapper
        def initialize(actor)
          @actor = actor
        end

        def publish(*args)
          actor << [:publish, *args]
        end

        def subscribe(*args)
          actor << [:subscribe, *args]
        end

        def subscribe!(*args)
          actor.ask!([:subscribe, *args])
        end

        def publish!(*args)
          actor.ask!([:publish, *args])
        end

        def connect!
          actor.ask!(:connect)
        end

        def disconnect!
          actor.ask!(:disconnect)
        end

        private

        attr_reader :actor
      end

      def self.spawn(transit, options)
        Wrapper.new(super(name, transit, options))
      end

      def initialize(transit, options = {})
        super()
        @transit = transit
        @options = options
      end

      def on_message((msg, *args))
        case msg
        when :publish
          publish(*args)
        when :subscribe
          subscribe(*args)
        when :connect
          connect
        when :disconnect
          disconnect
        else
          pass
        end
      end

      ##
      # Connect to the transporter.
      def connect
        raise NotImplementedError
      end

      ##
      # Disconnect from the transporter.
      def disconnect
        raise NotImplementedError
      end

      ##
      # Publish a message to the transporter.
      #
      # @param topic [String] The topic to publish to
      # @param message [String] The message to publish
      def publish(topic, message)
        raise NotImplementedError
      end

      ##
      # Subscribe to a topic on the transporter.
      #
      # @param service [String] The service name for which the subscription is being made
      # @param topic [String] The topic to subscribe to
      def subscribe(service, topic)
        raise NotImplementedError
      end

      def default_executor
        Concurrent.global_io_executor
      end

      private

      attr_reader :transit, :options

      def subscription_count
        raise NotImplementedError
      end
    end
  end
end
