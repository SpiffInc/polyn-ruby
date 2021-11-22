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
  module Transporters
    ##
    # The Base transporter defines the interface for all other transporters.
    # @abstract
    class Base < Concurrent::Actor::RestartingContext
      include SemanticLogger::Loggable

      def initialize(transit, _options = {})
        super()
        @transit = transit
      end

      def on_message((msg, *args))
        send(msg, *args)
      end

      def connect
        raise NotImplementedError
      end

      def disconnect
        raise NotImplementedError
      end

      def publish(topic, message)
        raise NotImplementedError
      end

      def subscribe(topic, &block)
        raise NotImplementedError
      end

      def default_executor
        Concurrent.global_io_executor
      end

      private

      attr_reader :transit
    end
  end
end
