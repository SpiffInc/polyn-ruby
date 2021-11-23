# frozen_string_literal: true

# Copyright 2021-2022 Jarod Reid
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

      logger.debug("serializer set to '#{serializer.class.name}'")

      @pool = Concurrent::ThreadPoolExecutor.new({
        min_threads: 5,
        max_threads: 10,
        max_queue:   20,
      })

      Service.pool = pool
    end

    ##
    # Publishes an event to the `Transporter`.
    #
    # @param topic [String] the topic to publish to
    # @param payload [Hash] the message payload
    def publish(topic, payload)
      logger.info("publishing to topic '#{topic}'")
      serialized = serializer.serialize(payload)
      transporter << [:publish, topic, serialized]
    end

    ##
    # @private
    def on_message((msg, *args))
      send(msg, *args)
    end

    private

    attr_reader :transporter, :pool, :serializer

    def receive(topic, payload)
      logger.info("received '#{payload}' on '#{topic}'")
      events[topic].each { |e| e.call(payload) }
    end

    def configure_transporter(options)
      transporter_class = infer_transporter(options)
      logger.info("transporter set to '#{transporter_class.name}'")
      @transporter      = transporter_class.spawn(
        "transporter",
        Concurrent::Actor.current,
        transporter_config_from(options),
      )
    end

    def transporter_config_from(options)
      if options.is_a?(Hash)
        options
      else
        {
          type: options.to_s,
        }
      end
    end

    def infer_transporter(options)
      case options
      when Hash
        options[:type]
      when Class
        options
      when Symbol, String
        Transporters.const_get(Utils::String.to_class_name(options.to_s).to_sym)
      end
    end
  end
end
