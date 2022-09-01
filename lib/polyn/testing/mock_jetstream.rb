# frozen_string_literal: true

module Polyn
  class Testing
    ##
    # Mock JetStream for applications to use in testing
    class MockJetStream
      def initialize(mock_nats)
        @mock_nats = mock_nats
        @real_nats = mock_nats.nats
      end

      def consumer_info(stream, consumer_name)
        @real_nats.jetstream.consumer_info(stream, consumer_name)
      end

      def find_stream_name_by_subject(subject)
        @real_nats.jetstream.find_stream_name_by_subject(subject)
      end
    end
  end
end
