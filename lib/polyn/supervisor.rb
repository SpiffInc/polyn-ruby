# frozen_string_literal: true

require_relative "transit"

module Polyn
  ##
  # Supervises Polyn Services
  class Supervisor < Concurrent::Actor::RestartingContext
    include SemanticLogger::Loggable

    def self.start(options = {})
      @main    = spawn(:root, options)
      @running = true

      Signal.trap("INT") do
        puts "Terminating..."
        shutdown
      end

      sleep 1 while @running
    end

    def self.shutdown
      logger.info("received 'SIGINT', shutting down...")
      @running = false
    end

    def initialize(options = {})
      super()
      @logger    = options[:log_options]
      set_semantic_logger
      logger.info "initializing"

      @services  = options.fetch(:services, [])
      @transit   = Transit.new(options.fetch(:transit, {}))

      start
    end

    def start
      logger.info("starting")
      register_services
    end

    def default_executor
      Concurrent.global_fast_executor
    end

    private

    attr_reader :services, :container, :log_options, :transit

    def register_services
      logger.info("registering services")
      services.each { |service| register_service(service) }
    end

    def register_service(service)
      transit.register(service)
    end

    def set_semantic_logger
      if log_options == $stdout || log_options.nil?
        SemanticLogger.add_appender(io: $stdout, formatter: :color)
      end
    end
  end
end
