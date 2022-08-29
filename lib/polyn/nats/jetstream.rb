# frozen_string_literal: true

module Polyn
  ##
  # Adapter/wrapper around Nats
  class JetStream
    def initialize(jetstream)
      @js = jetstream
    end

    def find_stream_name_by_subject(type)
      @js.find_stream_name_by_subject(type)
    end

    def pull_subscribe(type, consumer_name)
      @js.pull_subscribe(type, consumer_name)
    end

    def consumer_info(stream, consumer_name)
      @js.consumer_info(stream, consumer_name)
    end

    def key_value(name)
      @js.key_value(name)
    end
  end
end
