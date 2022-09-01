# frozen_string_literal: true

module Polyn
  class Testing
    ##
    # Mock Pull Subscription for applications to use in testing
    class MockPullSubscription
      def initialize(mock_nats, **opts)
        @mock_nats     = mock_nats
        @real_nats     = mock_nats.nats
        @subject == opts.fetch(:subject)
        @consumer_name = opts.fetch(:consumer_name)
      end

      def consumer_info(stream, consumer_name)
        @real_nats.jetstream.consumer_info(stream, consumer_name)
      end

      def find_stream_name_by_subject(subject)
        @real_nats.jetstream.find_stream_name_by_subject(subject)
      end

      def pull_subscribe(subject, consumer_name)
        Polyn::Testing::MockPullSubscription.new(
          mock_nats,
          subject:       subject,
          consumer_name: consumer_name,
        )
      end
    end
  end
end
