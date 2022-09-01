# frozen_string_literal: true

require "nats/io/msg"
require "polyn/naming"
require "polyn/testing/mock_jetstream"

module Polyn
  class Testing
    ##
    # Mock Nats connection for applications to use in testing
    class MockNats
      def initialize(nats)
        @nats        = nats
        @messages    = Queue.new
        @subscribers = []
      end

      def publish(subject, data, reply_to = nil, **opts)
        msg = NATS::Msg.new(subject: subject, data: data, reply: reply_to,
          header: opts[:header])
        send_to_subscribers(msg)
        @messages << msg
      end

      def subscribe(subject, _opts = {}, &callback)
        @subscribers << { subject: subject, callback: callback }
      end

      def jetstream
        @jetstream ||= MockJetStream.new(@nats)
      end

      private

      def send_to_subscribers(msg)
        @subscribers.each do |sub|
          sub[:callback].call(msg) if Polyn::Naming.subject_matches?(msg.subject, sub[:subject])
        end
      end
    end
  end
end
