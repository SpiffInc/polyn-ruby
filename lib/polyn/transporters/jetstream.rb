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

require "nats/client"

module Polyn
  module Transporters
    ##
    # Jetstream NATS transporter.
    class Jetstream < Base
      ##
      # @private
      class Envelope < Transporters::Envelope
        def initialize(topic, msg)
          super(topic, msg.data)
          @msg = msg
        end

        def acknowledge
          msg.ack
        end

        private

        attr_reader :msg
      end

      ##
      # @private
      class Subscription < Concurrent::Actor::RestartingContext
        include SemanticLogger::Loggable

        ##
        # @private
        class Wrapper
          def iniitalize(actor)
            @actor = actor
          end
        end

        def self.spawn(sub, transit)
          Wrapper.call(super(sub, transit))
        end

        def initialize(sub, transit)
          super
          @sub     = sub
          @transit = transit

          sub.fetch(1) do |messages|
            messages.each do |message|
              tx_message = Envelope.new(sub.subject, message)
              transit << [:receive, tx_message]
            end
          end
        end

        private

        attr_reader :sub, :transit
      end

      def initialize(transit, options = {})
        super
        @subscriptions = []
      end

      def connect
        logger.info("connecting")
        @nats   = NATS.connect(options)
        @client = nats.jetstream
      rescue Errno::ECONNREFUSED => e
        logger.error("connect failed: #{e}")
        raise Polyn::Transporters::Errors::TimeoutError, e
      end

      def disconnect
        logger.info("disconnecting")
        nats.close
      end

      private

      attr_reader :nats
    end
  end
end
