# frozen_string_literal: true

module Polyn
  class Testing
    ##
    # Mock Pull Subscription for applications to use in testing
    class MockPullSubscription
      def initialize(mock_nats, **opts)
        @mock_nats       = mock_nats
        @real_nats       = mock_nats.nats
        @subject         = opts.fetch(:subject)
        @consumer_name   = opts.fetch(:consumer_name)
        @stream          = update_stream
        @delivery_cursor = 0
        @mock_nats.add_consumer(self)
      end

      def fetch(batch = 1, **_params)
        start_pos        = @delivery_cursor
        end_pos          = start_pos + batch - 1
        update_cursor(end_pos)
        @stream[start_pos..end_pos]
      end

      def update_stream
        @stream = @mock_nats.messages.filter do |message|
          Polyn::Naming.subject_matches?(message.subject, @subject)
        end
        @stream
      end

      def update_cursor(end_pos)
        next_pos = end_pos + 1

        @delivery_cursor = if @stream[next_pos]
                             next_pos
                           else
                             @stream.length
                           end
      end
    end
  end
end
