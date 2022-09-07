# frozen_string_literal: true

require "nats/io/msg"
require "polyn/naming"
require "polyn/testing/mock_jetstream"
require "polyn/testing/mock_msg"
require "polyn/testing/mock_pull_subscription"

module Polyn
  class Testing
    ##
    # Mock Nats connection for applications to use in testing
    class MockNats
      def initialize(nats)
        @nats        = nats
        @messages    = []
        @subscribers = []
        @consumers   = []
      end

      attr_reader :nats, :messages

      def publish(subject, data, reply_to = nil, **opts)
        msg = Polyn::Testing::MockMsg.new(subject: subject, data: data, reply: reply_to,
          header: opts[:header])
        send_to_subscribers(msg)
        @messages << msg
        update_consumers
      end

      def subscribe(subject, _opts = {}, &callback)
        @subscribers << { subject: subject, callback: callback }
      end

      def jetstream
        @jetstream ||= MockJetStream.new(self)
      end

      def add_consumer(consumer)
        @consumers << consumer
      end

      private

      def send_to_subscribers(msg)
        @subscribers.each do |sub|
          sub[:callback].call(msg) if Polyn::Naming.subject_matches?(msg.subject, sub[:subject])
        end
      end

      def update_consumers
        @consumers.each(&:update_stream)
      end
    end
  end
end
