# frozen_string_literal: true

module Polyn
  class Testing
    ##
    # Mock JetStream for applications to use in testing
    class MockJetStream
      def initialize(nats)
        @nats = nats
      end

      def consumer_info(stream, consumer_name)
        @nats.jetstream.consumer_info(stream, consumer_name)
      end
    end
  end
end
