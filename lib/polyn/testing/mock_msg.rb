# frozen_string_literal: true

module Polyn
  class Testing
    class MockMsg
      def initialize(opts = {})
        @subject = opts[:subject]
        @reply   = opts[:reply]
        @data    = opts[:data]
        @header  = opts[:header]
      end

      attr_accessor :subject, :reply, :data, :header

      def ack(**params); end

      def ack_sync(**params); end

      def nak(**params); end

      def term(**params); end

      def in_progress(**params); end

      def metadata; end
    end
  end
end
