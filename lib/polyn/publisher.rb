# frozen_string_literal: true

module Polyn
  ##
  # The `Publisher` handles publishing messages to the event bus.
  class Publisher
    def initialize(transit)
      @transit = transit
    end

    ##
    # Publishes the given message to the event bus on the given topic.
    #
    # @param topic [String] The topic to publish the message to.
    # @param message [Hash] The message to publish.
    def publish(topic, message)
      Message.new(message)
    end

    private

    attr_reader :transit
  end
end
