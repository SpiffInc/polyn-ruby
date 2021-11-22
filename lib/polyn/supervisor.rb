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

require "forwardable"

require_relative "transit"

module Polyn
  ##
  # Supervises Polyn Services
  class Supervisor < Concurrent::Actor::RestartingContext
    include SemanticLogger::Loggable
    extend Forwardable

    def_delegators :@transit, :publish

    def self.spawn(options = {})
      super(:supervisor, options)
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
