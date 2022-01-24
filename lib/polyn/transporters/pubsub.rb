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
    # Pubsub provides a transporter for Google Cloud Pub/Sub. The Google Pubsub transporter makes no
    # attempt to set up the topic or subscription. It is up to the developer to ensure that the
    # topic and subscription exist. Various options are available to configure google pubsub,
    # such as
    # [Terraform](https://registry.terraform.io/modules/terraform-google-modules/pubsub/google/latest).
    #
    # If the topic or subscription are not created, the transporter will throw an exception.
    #
    # @param transit [Polyn::Transit] the transit actor
    # @param options [Hash] the options for the transporter
    # @option options [String] :project_id the project_id to use
    # @option options [String] :credentials the credential information
    # @option options [String] :emulator_host the hostname of the emulator
    # @option options [Integer] :timeout the connection timeout for the transporter, defaults to 5 seconds
    class Pubsub < Base
      ##
      # @private
      class Envelope < Transporters::Envelope
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

      def initialize(transit, options = {})
        super
        @subscribers = []
      end

      def connect
        logger.info("connecting")
        @client = Google::Cloud::Pubsub.new(**{ timeout: 5 }.merge(options))
        verify_client!
        logger.info("connected")
      end

      def disconnect
        logger.info("disconnecting")
        logger.info("stopping '#{subscribers.length}' subscribers")
        subscribers.each(&:stop)
        logger.info("disconnected")
      end

      def publish(type, event)
        logger.debug("publishing to topic '#{type}'")
        gcp_topic = client.topic(type)
        logger.debug("got topic '#{gcp_topic}'")

        gcp_topic.publish(event)
        logger.debug("published message")
      rescue Google::Cloud::DeadlineExceededError => e
        logger.error("timeout while publishing to topic '#{type}'", e)
        raise Errors::TimeoutError.new(e,
          "the transporter timed out attempting to topic '#{type}'")
      end

      def subscribe(service_name, topic)
        logger.debug("subscribing to topic '#{topic}'")
        subscription = subscription_for_topic("#{service_name}-#{topic}")

        create_subscriber_for_subscription(subscription)
      rescue Google::Cloud::DeadlineExceededError => e
        logger.error("timeout while subscribing to topic '#{topic}'", e)
        raise Errors::TimeoutError.new(e,
          "the transporter timed out attempting to subscribe to topic '#{topic}'")
      end

      private

      attr_reader :client, :subscribers

      def verify_client!
        # this will make a rest call to google pubsub and verify the connection
        client.topics
      rescue Google::Cloud::DeadlineExceededError => e
        logger.error("timeout while verifying connection", e)
        raise Errors::TimeoutError.new(e,
          "the transporter timed out attempting to verify connection")
      end

      def subscription_for_topic(topic)
        logger.debug("looking up pubsub subscription for topic '#{topic}'")
        subscription = client.subscription(topic)

        unless subscription
          raise Errors::TopicNotFoundError,
            "topic '#{topic}' not found"
        end

        subscription
      end

      def create_subscriber_for_subscription(subscription)
        logger.debug("setting listener")
        subscriber = subscription.listen do |message|
          logger.debug("received message on '#{subscription.name}'")
          tx_message = Envelope.new(subscription.topic.name.split("/").last, message)

          transit << [:receive, tx_message]
        end

        subscribers << subscriber

        subscriber.start

        logger.debug("listener set '#{subscriber}'")
      end
    end
  end
end
