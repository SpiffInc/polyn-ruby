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
  # Abstracts the transportation logic of Polyn.  Transit works with the configured
  # Transporter to send the message to the Event Bus.
  class Transit < Concurrent::Actor::RestartingContext
    ##
    # @private
    class Wrapper
      include SemanticLogger::Loggable

      def initialize(actor)
        @actor = actor
      end

      def publish(*args)
        actor << [:publish, *args]
      end

      def shutdown
        actor.ask!(:shutdown)
      rescue Concurrent::Actor::ActorTerminated
        logger.warn("the transit actor was already terminated")
      end

      private

      attr_reader :actor
    end

    include SemanticLogger::Loggable

    def self.spawn(*args)
      Wrapper.new(super(:transit, *args))
    end

    ##
    # @param options [Hash] the transit options
    # @option options [Symbol|String|Class<Transporters::Base>|Hash] :transporter the transporter
    #   configuration
    def initialize(reactor_manager, options = {})
      super()
      logger.info("starting")
      configure_transporter(options.fetch(:transporter, :internal))

      @reactor_manager = reactor_manager
      @serializer      = Serializers.for(options.fetch(:serializer))
      @origin          = options.fetch(:origin)

      logger.debug("serializer set to '#{serializer.class.name}'")

      # Set the service pool to use the Transit thread pool.
      Reactor.pool = pool

      subscribe_to_events!
    end

    ##
    # @private
    def on_message((msg, *args))
      puts msg  + "\n\n\n\n"
      case msg
      when :publish
        publish(*args)
      when :receive
        receive(*args)
      when :shutdown
        logger.warn("shutting down")
        begin
          transporter.disconnect!
        rescue Concurrent::Actor::ActorTerminated
          logger.warn("transporter already terminated")
        end
      else
        pass
      end
    end

    private

    attr_reader :transporter, :serializer, :origin, :reactor_manager

    def events
      @events ||= service_manager.ask!(:reactors).map { |s| s.events.values }.flatten
    end

    # iterates through all the services and subscribes to the events
    def subscribe_to_events!
      logger.info("subscribing to events")
      events.each do |event|
        logger.debug("service '#{event.reactor.name}' is subscribing ito event '#{event.topic}'")
        transporter.subscribe!(event.reactor.name, event.topic)
      end
    end

    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new({
        min_threads: 5,
        max_threads: 10,
        max_queue:   20,
      })
    end

    ##
    # Publishes the event to the configured transporter.
    #
    # @param event [Polyn::Event] the event to publish
    def publish(event)
      logger.info("publishing to topic '#{event.type}'")

      serialized = serializer.serialize(event)
      transporter.publish!(event.type, serialized)
    end

    ##
    # Receives an event from the trnasporter.
    #
    # @param envelope [Polyn::Transporters::Envelope] the envelope to receive
    def receive(envelope)
      serializer.deserialize(envelope.event).tap do |event|
        logger.info("received message from topic '#{envelope.type}'")
        context = Context.new(
          event:    event,
          envelope: envelope,
        )

        service_manager << [:receive, context]
      end
    end

    def configure_transporter(options)
      transporter_class = Transporters.for(options)
      logger.info("transporter set to '#{transporter_class.name}'")
      @transporter      = transporter_class.spawn(
        Concurrent::Actor.current,
        transporter_config_from(options),
      )

      transporter.connect!
    end

    def transporter_config_from(options)
      if options.is_a?(Hash)
        options[:options]
      else
        {}
      end
    end
  end
end
