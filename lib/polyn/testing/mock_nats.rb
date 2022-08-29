# frozen_string_literal: true

require "nats/io/msg"

module Polyn
  class Testing
    class MockNats
      def initialize
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

      private

      def send_to_subscribers(msg)
        @subscribers.each do |sub|
          sub[:callback].call(msg) if sub[:subject] == msg.subject
        end
      end
    end
  end
end