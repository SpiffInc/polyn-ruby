# frozen_string_literal: true

# Copyright 2021-2022 Spiff, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "securerandom"

module Polyn
  ##
  # Represents a Polyn message.
  class Message
    def initialize(topic:, origin:, payload:, parent: nil, service: nil)
      @topic      = topic
      @payload    = payload
      @service    = service
      @origin     = origin
      @trace      = []
      @created_at = Time.now.utc
      @uuid       = SecureRandom.uuid
    end

    ##
    # Prepares a message for transit.
    #
    # @return [Hash] a hash representation of the message provided for transit.
    def for_transit
      {
        topic:     topic,
        eventId:   uuid,
        origin:    origin,
        createdAt: created_at,
        client:    {
          type:    "ruby",
          version: Polyn::VERSION,
        },
        trace:     trace,
        payload:   payload,
      }
    end

    private

    attr_reader :topic, :payload, :service, :origin, :trace, :created_at, :uuid
  end
end
