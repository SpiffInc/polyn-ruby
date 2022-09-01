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

      def find_stream_name_by_subject(subject)
        @nats.jetstream.find_stream_name_by_subject(subject)
      end
    end
  end
end
