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

module Polyn
  ##
  # A service is an event handler on the Polyn event bus.
  class Service < Concurrent::Actor::Context
    include SemanticLogger::Loggable

    ##
    # Represents an event handler within a Polyn service.
    #
    # @param service [Polyn::Service] The service this handler belongs to.
    # @param topic [String] The topic to subscribe to.
    # @param method [Symbol] The event handler method to call on the service.
    # @param options [Hash] Event handler options
    class EventHandler
      include SemanticLogger::Loggable
      ##
      # @return [String] The topic this event handler is subscribed to.
      attr_reader :topic, :service

      def initialize(service, topic, method, options = {})
        @topic   = topic
        @method  = method
        @options = options
        @service = service
      end

      def call(payload)
        logger.info("calling '#{method}' on '#{service.name}'")
        logger.info("spawning '#{service.name}'")
        actor = service.spawn("#{service.name}-#{topic}")
        logger.info("#{service.name} spawned with actor '#{actor}'")
        actor << [:call, method, payload]
      end

      private

      attr_reader :method
    end

    ##
    # List of invalid event handlers
    INVALID_EVENT_HANDLERS = %i[transporter].freeze

    class << self
      ##
      # @return [Hash{String => EventHandler}] the events defined in the service
      attr_reader :events

      ##
      # Processes incoming events and calls the appropriate event handler.
      #
      # @param context [Polyn::Context] The context of the event.
      def receive(context)
        topic = context.topic
        return unless events[topic]

        logger.debug("receiving event '#{topic}'")
        events[topic].call(context)
      end

      ##
      # @return [Symbol] the service of the current thread
      def current_service_name
        Thread.local[:polyn_current_service_name] || :root
      end

      ##
      # Defines an event handler for a service for the specified topic
      #
      # @param topic [String] the topic to listen on
      # @param method [Symbol] the method to call when the event is received
      def event(topic, method)
        @events      ||= {}
        validate(topic, method)
        @events[topic] = EventHandler.new(self, topic, method)
      end

      ##
      # Gets or sets the service name
      #
      # @param name [String] the service name, if nil then the service name is returned
      def name(name = nil)
        @service_name = name if name
        @service_name
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
        return if topic.is_a?(String)

        raise ArgumentError,
          "Topic must be a String or Regexp, instead it is a '#{topic.class}'"
      end

      ##
      # Sets the service thread pool
      #
      # @param pool [Concurrent::ThreadPoolExecutor] the thread pool to use
      def pool=(pool)
        @@pool = pool
      end

      ##
      # @return [Concurrent::ThreadPoolExecutor] the thread pool to use
      def pool
        @@pool ||= Concurrent::FixedThreadPool.new(10)
      end
    end

    def on_message((msg, *args))
      case msg
      when :call
        (method, *args) = args
        logger.info("calling '#{method}'")
        public_send(method, *args)
        logger.trace("terminating")
        Concurrent::Actor.current.ask!(:terminate!)
      when :terminated
        logger.warn("service was terminated.")
      else
        raise ArgumentError, "Unknown message '#{msg}'"
      end
    end

    ##
    # @private
    def default_executor
      self.class.pool
    end

    private

    def events
      self.class.events
    end

    def name
      self.class.name
    end
  end
end
