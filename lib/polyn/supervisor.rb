# frozen_string_literal: true

module Polyn
  ##
  # Supervises Polyn Services
  class Supervisor < Concurrent::Actor::RestartingContext
    include SemanticLogger::Loggable

    def self.spawn(options = {})
      super(:root, options)
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
    end

    private

    attr_reader :services, :container, :log_options

    def set_semantic_logger
      if log_options == $stdout || log_options.nil?
        SemanticLogger.add_appender(io: $stdout, formatter: :color)
      else
      end
    end
  end
end
