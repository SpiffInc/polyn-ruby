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
  # The ServiceManager is responsible for managing the life cycle of services.
  class ReactorManager < Concurrent::Actor::Context
    ##
    # @private
    class Wrapper
      include SemanticLogger::Loggable

      def initialize(actor)
        @actor = actor
      end

      def receive(*args)
        actor.ask!(:receive, *args)
      end

      def reactors
        actor.ask!(:reactors)
      end

      def shutdown
        actor.ask!(:shutdown)
      rescue Concurrent::Actor::ActorTerminated
        logger.warn("reactor manager was already terminated")
      end

      private

      attr_reader :actor
    end

    include SemanticLogger::Loggable

    ##
    # @private
    def self.spawn(services)
      Wrapper.new(super(:reactor_manager, services))
    end

    ##
    # @param services [Array<Polyn::Reactor>] the services for this node.
    def initialize(config)
      super()
      @reactors = config.fetch(:reactors, [])
    end

    ##
    # @private
    def on_message((msg, *args))
      case msg
      when :receive
        receive(*args)
      when :reactors
        reactors
      when :shutdown
        logger.warn("reactor manager was asked to shut down")
      else
        pass
      end
    end

    private

    attr_reader :reactors

    def receive(context)
      reactors.each do |reactor|
        reactor.receive(context)
      end
    end
  end
end
