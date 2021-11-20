# frozen_string_literal: true

module Polyn
  ##
  # A service is an event handler on the Polyn event bus.
  class Service < Concurrent::Actor::RestartingContext
    include SemanticLogger::Loggable

    ##
    # Represents an event handler within a Polyn service.
    #
    # @param service [Polyn::Service] The service this handler belongs to.
    # @param topic [String] The topic to subscribe to.
    # @param method [Symbol] The event handler method to call on the service.
    # @param options [Hash] Event handler options
    class EventHandler
      ##
      # @return [String] The topic this event handler is subscribed to.
      attr_reader :topic, :service

      def initialize(service, topic, method, options = {})
        @topic   = topic
        @method  = method
        @options = options
        @service = service
      end
    end

    ##
    # List of invalid event handlers
    INVALID_EVENT_HANDLERS = %i[transporter].freeze

    class << self
      ##
      # @return [Hash{String => EventHandler}] the events defined in the service
      attr_reader :events

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

      def pool
        @@pool
      end
    end

    ##
    # @param transporter [Poly::Transporter] the transporter to use for sending events
    def initialize(transporter: nil)
      super()
      @transporter = transporter
      validate_service
      start
    end

    ##
    # @private
    def default_executor
      self.class.pool
    end

    private

    attr_reader :transporter

    def start
      logger.info("starting")
      subscribe_events
    end

    def subscribe_events
      logger.info("subscribing to all events")
      self.class.events.each_value { |event| subscribe_event(event) }
    end

    def subscribe_event(event)
      logger.info("subscribing to event '#{event.topic}'")
    end

    def validate_service
      return unless name.nil? || name == ""

      raise Errors::ServiceNameError, name
    end

    def name
      self.class.name
    end
  end
end
