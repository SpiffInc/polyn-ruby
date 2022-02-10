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

require_relative "base"

module Polyn
  module Transporters
    ##
    # Internal transporter for use in testing.
    class Internal < Base
      ##
      # @private
      class Envelope < Polyn::Transporters::Envelope
        def acknowledge; end
      end

      def initialize(transit, options = {})
        super(transit, options)
        if Object.const_defined?("::Rails")
          logger.warn("WARNING, the internal transporter is not supported within Rails.")
        end
        @subscriptions = []
      end

      def connect
        logger.info("connected")
        true
      end

      def disconnect
        logger.info("disconnected")
        true
      end

      def publish(type, event)
        logger.debug("publishing to topic '#{type}'")
        tx_message = Envelope.new(type, event)

        transit << [:receive, tx_message] if subscriptions.include?(type)
      end

      def subscribe(_service_name, type)
        logger.debug("subscribing to topic '#{type}'")
        subscriptions << type
      end

      private

      attr_reader :subscriptions
    end
  end
end
