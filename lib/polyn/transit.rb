# frozen_string_literal: true

module Polyn
  ##
  # Abstracts the transportation logic of Polyn. Transit tracks all registered services
  # for the process and
  class Transit
    include SemanticLogger::Loggable

    ##
    # @param options [Hash] the transit options
    # @option options [Symbol|String|Class<Transporters::Base>|Hash] :transporter the transporter
    #   configuration
    def initialize(options = {})
      transporter_config = options.fetch(:transporter, :internal)
      logger.debug("loading transporter for config '#{transporter_config}'")
      @transporter       = Transporters.for(transporter_config)
      logger.info("transporter set to '#{transporter.name}'")
      @serializer        = Serializers.for(:json)

      @pool = Concurrent::ThreadPoolExecutor.new({
                                                   min_threads: 5,
                                                   max_threads: 10,
                                                   max_queue:   20,
                                                 })

      Service.pool = pool

      @services          = {}
      @events            = {}
    end

    ##
    # Starts the transit
    def start
      transporter.start
    end

    ##
    # Registers a service, and any events it will consume.
    #
    # @param service [Class<Polyn::Service>] the service to register
    def register(service)
      logger.info("registering service '#{service.name}'")
      services[service.name] = service
      register_events_for(service)
    end

    private

    attr_reader :services, :events, :transporter, :pool


    def register_events_for(service)
      service.events.each_value { |event| register_event(event) }
    end

    def register_event(event)
      logger.info("registering event '#{event.topic}' for service '#{event.service.name}'")
      events[event.topic] ||= []
      events[event.topic] << event
      transporter.subscribe(event.topic) do |payload|
        message = Message.new(serializer.deserialize(payload))
      end
    end
  end
end
