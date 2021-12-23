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

require "google/cloud/pubsub"

module Polyn
  module Transporters
    ##
    # Pubsub provides a transporter for Google Cloud Pub/Sub.
    #
    # @param transit [Polyn::Transit] the transit actor
    # @param options [Hash] the options for the transporter
    # @option options [String] :project_id the project_id to use
    # @option options [String] :credentials the credential information
    # @option options [String] :emulator_host the hostname of the emulator
    class Pubsub < Base
      ##
      # @private
      class Message < Polyn::Transporters::Message
        def initialize(topic, msg)
          super(topic, msg.data)
          @msg = msg
        end

        def acknowledge
          msg.acknowledge!
        end

        private

        attr_reader :msg
      end

      def initialize(*arg)
        super
        @subscriptions = []
      end

      def connect
        logger.info("connecting")
        @client = Google::Cloud::Pubsub.new(**options)
        logger.info("connected")
      end

      def disconnect
        logger.info("disconnecting")
        logger.info("stopping '#{subscriptions.length}' subscribers")
        subscriptions.each(&:stop)
        logger.info("disconnected")
      end

      def publish(topic, message)
        logger.debug("publishing to topic '#{topic}'")
        Timeout.timeout(5) do
          gcp_topic = client.topic(topic)
          logger.debug("got topic '#{gcp_topic}'")

          gcp_topic.publish(message)
          logger.debug("published message")
        end
      end

      def subscribe(topic)
        logger.debug("subscribing to topic '#{topic}'")
        Timeout.timeout(5) do
          subscription = client.subscription(topic)

          raise Polyn::Errors::TransporterTopicNotFoundError, "topic '#{topic}' not found" unless subscription

          logger.debug("setting listener")
          subscriber = subscription.listen do |message|
            logger.debug("received message on '#{topic}'")
            tx_message = Message.new(topic, message)

            transit << [:receive, tx_message]
          end

          subscriber.on_error do |exception|
            logger.error(exception)
          end

          subscriptions << subscriber

          subscriber.start

          logger.debug("listener set '#{subscriber}'")
        end
      rescue Timeout::Error
        logger.error("timeout while subscribing to topic '#{topic}'")
        raise Polyn::Errors::TransporterTimeoutError,
          "the transporter timed out attempting to subscribe to topic '#{topic}'"
      end

      private

      attr_reader :client, :subscriptions
    end

  end
end
