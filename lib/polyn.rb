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

# Loading all our classes up front
require "json_schemer"
require "json"
require "nats/client"
require "securerandom"

require "polyn/configuration"
require "polyn/cloud_event"
require "polyn/errors/errors"
require "polyn/event"
require "polyn/naming"
require "polyn/nats/nats"
require "polyn/nats/jetstream"
require "polyn/pull_subscriber"
require "polyn/schema_store"
require "polyn/serializers/json"
require "polyn/utils/utils"
require "polyn/version"

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

    # Ensure accidental message duplication doesn't happen
    # https://docs.nats.io/using-nats/developer/develop_jetstream/model_deep_dive#message-deduplication
    msg_id_header = { "Nats-Msg-Id" => event.id }
    header        = opts.fetch(:header, {})
    header        = msg_id_header.merge(header)

    json = Polyn::Serializers::Json.serialize!(nats, event, **opts)

    nats_class.new(nats).publish(type, json, opts[:reply_to], header: header)
  end

  ## Create subscription which is dispatched asynchronously
  # and sends messages to a callback.
  #
  # @param nats [Object] Connected NATS instance from `NATS.connect`
  # @param type [String] The type of event
  # @option options [String] :queue - Queue group to add subscriber to
  # @option options [String] :max - Max msgs before unsubscribing
  # @option options [String] :pending_msgs_limit
  # @option options [String] :pending_bytes_limit
  def self.subscribe(nats, type, opts = {}, &callback)
    nats_class.new(nats).subscribe(type, opts) do |msg|
      event    = Polyn::Serializers::Json.deserialize!(nats, msg.data,
        store_name: opts[:store_name])
      msg.data = event
      callback.call(msg)
    end
  end

  ##
  # Subscribe to a pull consumer that already exists in the NATS server
  #
  # @param nats [Object] Connected NATS instance from `NATS.connect`
  # @param type [String] The type of event
  # @option options [String] :source - If the `source` portion of the consumer name
  # is more than the `source_root`
  def self.pull_subscribe(nats, type, **opts)
    Polyn::PullSubscriber.new({ nats: nats_class.new(nats), type: type, source: opts[:source] })
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

  def self.nats_class
    if configuration.polyn_env == "test"
      Polyn::MockNats
    else
      Polyn::Nats
    end
  end
end
