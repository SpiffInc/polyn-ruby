# frozen_string_literal: true

##
# Monkey Patch ConsumerConfig to ensure that nil values are removed on a
# call to `to_json` even if ActiveSupport is being used.
# @see https://github.com/nats-io/nats-pure.rb/issues/67
class NATS::JetStream::API::ConsumerConfig
  def as_json(*args)
    to_h.compact.as_json(*args)
  end
end
