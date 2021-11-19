# frozen_string_literal: true

module Polyn
  ##
  # Supervises Polyn Services
  class Supervisor < Concurrent::Actor::RestartingContext
    include SemanticLogger::Loggable

    def self.start(options = {})
      spawn(:root, options)
      loop do
        sleep 1
      end
    end

    def initialize(options = {})
      super()
      @logger    = options[:log_options]
      @services  = options.fetch(:services, [])

      set_semantic_logger
      start
    end

    def start
      logger.info("starting")
      start_services
    end

    private

    attr_reader :services, :container, :log_options

    def start_services
      logger.info("starting services")
      services.each {|service| start_service(service) }
    end

    def start_service(service)
      logger.info("starting service '#{service}'")
      service.spawn(service.name)
    end

    def set_semantic_logger
      if log_options == $stdout || log_options.nil?
        SemanticLogger.add_appender(io: $stdout, formatter: :color)
      else
      end
    end
  end
end
