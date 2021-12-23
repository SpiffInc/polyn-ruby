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
    include SemanticLogger::Loggable

    def self.spawn(*args)
      super(:transit, *args)
    end

    ##
    # @param options [Hash] the transit options
    # @option options [Symbol|String|Class<Transporters::Base>|Hash] :transporter the transporter
    #   configuration
    def initialize(service_manager, options = {})
      super()
      logger.info("starting")
      configure_transporter(options.fetch(:transporter, :internal))

      @service_manager = service_manager
      @serializer      = Serializers.for(:json).new
      @origin          = options.fetch(:origin)

      logger.debug("serializer set to '#{serializer.class.name}'")

      # Set the service pool to use the Transit thread pool.
      Service.pool = pool

      subscribe_to_events
      @ready = true
    end

    ##
    # @private
    def on_message((msg, *args))
      case msg
      when :publish
        publish(*args)
      when :receive
        receive(*args)
      when :ready?
        @ready
      else
        pass
      end
    end

    private

    attr_reader :transporter, :serializer, :origin, :service_manager

    def events
      @events ||= service_manager.ask!(:services).map { |s| s.events.values }.flatten
    end

    # iterates through all the services and subscribes to the events
    def subscribe_to_events
      logger.info("subscribing to events")
      events.each do |event|
        logger.debug("service '#{event.service.name}' is subscribing ito event '#{event.topic}'")
        transporter << [:subscribe, event.topic]
      end
      logger.info("waiting for subscriptions to be ready")
      sleep 0.1
      logger.info("subscriptions ready")
    end

    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new({
        min_threads: 5,
        max_threads: 10,
        max_queue:   20,
      })
    end

    def message_for(topic, payload)
      Message.new(
        origin:  origin,
        topic:   topic,
        payload: payload,
      )
    end

    def publish(topic, payload)
      logger.info("publishing to topic '#{topic}'")
      message = message_for(topic, payload)

      serialized = serializer.serialize(message.for_transit)
      transporter << [:publish, topic, serialized]
    end

    def receive(message)
      serializer.deserialize(message.data).tap do |deserialized|
        logger.info("received message from topic '#{message.topic}'")
        context = Context.new(message: Utils::Hash.deep_symbolize_keys(deserialized), raw: message)

        service_manager << [:receive, message.topic, context]
      end
    end

    def configure_transporter(options)
      transporter_class = Transporters.for(options)
      logger.info("transporter set to '#{transporter_class.name}'")
      @transporter      = transporter_class.spawn(
        Concurrent::Actor.current,
        transporter_config_from(options),
      )

      transporter.ask!(:connect)
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
