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
require_relative "reactor_manager"

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
      @name          = options.fetch(:name)
      @source_prefix = options.fetch(:source_prefix)
      @hostname      = Socket.gethostname
      @pid           = Process.pid

      transit = options.fetch(:transit, {})

      transit.merge!({
                       origin: "#{name}@#{hostname}<#{pid}>",
                     })

      logger.debug("starting reactor manager")
      @reactor_manager = ReactorManager.spawn(options.fetch(:reactors, { reactors: [] }))
      logger.debug("starting transit")
      @transit         = Transit.spawn(reactor_manager, transit)
    end

    ##
    # Publishes a message to the transit `Actor`
    #
    # @param type [String] the event type to publish
    # @param payload [Hash] the message to publish
    def publish(type, payload)
      event = Event.new({
                          type:   type,
                          source: "#{source_prefix}.#{name}",
                          data:   payload,
                        })

      transit.publish(event)
    end

    ##
    # @private
    def on_message((msg, *args))
      case msg
      when :publish
        publish(*args)
      when :terminated
        begin
          logger.fatal("there was a problem with initializing the Polyn application, shutting down" \
                         " Check logs for details.")
          transit.shutdown
          reactor_manager.shutdown
        ensure
          abort
        end
      else
        pass
      end
    end

    ##
    # @private
    def default_executor
      Concurrent.global_fast_executor
    end

    private

    attr_reader :reactor_manager, :container, :log_options, :transit, :hostname, :pid, :source_prefix

    def origin
      "#{name}/#{hostname}/#{pid}"
    end
  end
end
