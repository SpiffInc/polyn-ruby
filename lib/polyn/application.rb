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

require_relative "transit"
require_relative "service_manager"

module Polyn
  ##
  # A Polyn Application. Only a single instance of this class should be created per
  # process.
  class Application < Concurrent::Actor::RestartingContext
    include SemanticLogger::Loggable

    ##
    # @return [String] The name of the application.
    attr_reader :name

    ##
    # @private
    def self.spawn(options)
      super(:supervisor, options)
    end

    def self.shutdown
      logger.info("received 'SIGINT', shutting down...")
    end

    ##
    # @param options [Hash] Polyn options.
    # @option options [String] :name The name of the application.
    # @option options [Hash] :validator The validator to use.
    def initialize(options)
      super()
      logger.info "initializing"
      @name     = options.fetch(:name)
      @hostname = Socket.gethostname
      @pid      = Process.pid

      configure_validator(options.fetch(:validator))
      transit = options.fetch(:transit, {})

      transit.merge!({
        origin: "#{name}@#{hostname}<#{pid}>",
      })

      @service_manager = ServiceManager.spawn(:service_manager, options.fetch(:services, []))
      @transit         = Transit.spawn(:transit, service_manager, transit)
    end

    ##
    # Publishes a message to the transit `Actor`
    #
    # @param topic [String] the topic to publish to
    # @param payload [Hash] the message to publish
    def publish(topic, payload)
      payload = Utils::Hash.deep_camelize_keys(payload).freeze
      errors  = validator.validate(topic, payload)

      raise Errors::PayloadValidationError, errors unless errors.empty?

      transit << [:publish, topic, payload]
    end

    ##
    # @private
    def on_message((msg, *args))
      send(msg, *args)
    end

    ##
    # @private
    def default_executor
      Concurrent.global_fast_executor
    end

    private

    attr_reader :service_manager, :container, :log_options, :transit, :validator, :hostname, :pid

    def origin
      "#{name}/#{hostname}/#{pid}"
    end

    def configure_validator(validator)
      @validator = Validators.for(validator)
    end
  end
end
