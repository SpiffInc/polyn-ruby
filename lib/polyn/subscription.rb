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

require "nats"

module Polyn
  ##
  # Manages a single JetStream subcription.
  class Subscription < Concurrent::Actor::Context
    # @private
    class Wrapper
      def initialize(actor)
        @actor = actor
      end

      def start
        actor << :next
      end

      def stop
        actor << :stop
      end

      private

      attr_reader :actor
    end

    def self.spawn(*args)
      Wrapper.new(super("sub-", *args))
    end

    def initialize(transit, sub)
      super()
      @sub     = sub
      @transit = transit
      @running = true
    end

    # @private
    def on_message(msg)
      case msg
      when :next
        begin
          return unless running?
          return self << :next if pending.zero?

          transit << [:receive, sub.fetch(1)]

          self << :next
        end
      when :stop
        @running = false
      end
    end

    private

    attr_reader :transit, :sub

    def info
      sub.consumer_info
    end

    def pending
      info.num_pending
    end

    def running?
      @running
    end
  end
end
