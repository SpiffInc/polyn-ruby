# frozen_string_literal: true

module Polyn
  class Nats
    ##
    # Wrapper around Nats::Msg so that we own it
    class Msg
      def initialize(msg)
        @msg = msg
      end

      attr_accessor :subject, :reply, :data, :header

      def subject
        @msg.subject
      end

      def reply
        @msg.reply
      end

      def data
        @msg.data
      end

      def data=(data)
        @msg.data = data
      end

      def header
        @msg.header
      end

      def ack(**params)
        @msg.ack(**params)
      end

      def ack_sync(**params)
        @msg.ack_sync(**params)
      end

      def nak(**params)
        @msg.nack(**params)
      end

      def term(**params)
        @msg.term(**params)
      end

      def in_progress(**params)
        @msg.in_progress(**params)
      end

      def metadata
        @msg.metadata
      end

      def respond(data = "")
        @msg.respond(data)
      end

      def respond_msg(msg)
        @msg.respond_msg(msg)
      end

      def inspect
        @msg.inspect
      end
    end
  end
end
