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

require "concurrent/actor"
require "semantic_logger"

require_relative "polyn/configuration"
require_relative "polyn/version"
require_relative "polyn/utils"
require_relative "polyn/event"
require_relative "polyn/exception_handlers"
require_relative "polyn/serializers/json"

##
# Polyn is a Reactive service framework.
module Polyn
  ##
  # Publishes a message on the Polyn network.
  #
  # @param nats [Object] Connected NATS instance from `NATS.connect`
  # @param type [String] The type of event
  # @param data [any] The data to include in the event
  # @option options [String] :source - information to specify the source of the event
  # @option options [String] :triggered_by - The event that triggered this one.
  # Will use information from the event to build up the `polyntrace` data
  # @option options [String] :reply_to - Reply to a specific topic
  # @option options [String] :header - Headers to include in the message
  def self.publish(nats, type, data, **opts)
    event = Event.new({
      type:         type,
      source:       opts[:source],
      data:         data,
      triggered_by: opts[:triggered_by],
    })

    json = Polyn::Serializers::Json.serialize!(nats, event, opts)

    nats.publish(type, json, opts[:reply_to], header: opts[:header])
  end

  ##
  # Configuration information for Polyn
  def self.configuration
    @configuration ||= Configuration.new
  end

  ##
  # Configuration block to configure Polyn
  def self.configure
    yield(configuration)
  end
end
