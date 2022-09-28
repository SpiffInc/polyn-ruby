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
require "opentelemetry"
require "securerandom"

require "polyn/configuration"
require "polyn/cloud_event"
require "polyn/errors/errors"
require "polyn/event"
require "polyn/naming"
require "polyn/nats"
require "polyn/nats/msg"
require "polyn/nats/jetstream/api/consumer_config"
require "polyn/pull_subscriber"
require "polyn/schema_store"
require "polyn/serializers/json"
require "polyn/testing/mock_nats"
require "polyn/tracing"
require "polyn/utils/utils"
require "polyn/version"

##
# Polyn is a Reactive service framework.
module Polyn
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

  ##
  # Connects Polyn to a NATS connection and loads all event schemas
  #
  # @param nats [NATS::IO::Client] A nats connection instance
  def self.connect(nats, **opts)
    Conn.new(nats, **opts)
  end

  ##
  # A Polyn connection to NATS
  class Conn
    def initialize(nats, **opts)
      @nats         = nats_class.new(nats)
      # Schema store nats has to be a real one, not a mock, because
      # the only place to load the schemas is from a running nats-server
      @schema_store = opts[:schema_store] || schema_store(nats, **opts)
      @serializer   = Polyn::Serializers::Json.new(@schema_store)
    end

    ##
    # Publishes a message on the Polyn network.
    #
    # @param type [String] The type of event
    # @param data [any] The data to include in the event
    # @option options [String] :source - information to specify the source of the event
    # Will use information from the event to build up the `polyntrace` data
    # @option options [String] :reply_to - Reply to a specific topic
    # @option options [String] :header - Headers to include in the message
    def publish(type, data, **opts)
      Polyn::Tracing.publish_span(type) do |span|
        event = Event.new({
          type:   type,
          source: opts[:source],
          data:   data,
        })

        json = @serializer.serialize!(event)

        Polyn::Tracing.span_attributes(span,
          nats:    @nats.nats,
          type:    type,
          event:   event,
          payload: json)

        header = add_headers(opts.fetch(:header, {}), event)

        @nats.publish(type, json, opts[:reply_to], header: header)
      end
    end

    ## Create subscription which is dispatched asynchronously
    # and sends messages to a callback.
    #
    # @param type [String] The type of event
    # @option options [String] :queue - Queue group to add subscriber to
    # @option options [String] :max - Max msgs before unsubscribing
    # @option options [String] :pending_msgs_limit
    # @option options [String] :pending_bytes_limit
    def subscribe(type, opts = {}, &callback)
      @nats.subscribe(type, opts) do |msg|
        Polyn::Tracing.subscribe_span(type, msg) do |span|
          event    = @serializer.deserialize!(msg.data)

          Polyn::Tracing.span_attributes(span,
            nats:    @nats.nats,
            type:    type,
            event:   event,
            payload: msg.data)

          msg.data = event
          callback.call(msg)
        end
      end
    end

    ##
    # Subscribe to a pull consumer that already exists in the NATS server
    #
    # @param nats [Object] Connected NATS instance from `NATS.connect`
    # @param type [String] The type of event
    # @option options [String] :source - If the `source` portion of the consumer name
    # is more than the `source_root`
    def pull_subscribe(type, **opts)
      Polyn::PullSubscriber.new({
        nats:       @nats,
        type:       type,
        source:     opts[:source],
        serializer: @serializer,
      })
    end

    private

    def schema_store(nats, **opts)
      if Polyn.configuration.polyn_env == "test"
        # For application tests reuse the same schema_store so we don't
        # waste time fetching the schemas on every test
        Thread.current[:polyn_schema_store]
      else
        Polyn::SchemaStore.new(nats, name: opts[:store_name])
      end
    end

    ##
    # NATS connection class to use based on environment
    def nats_class
      if Polyn.configuration.polyn_env == "test"
        Polyn::Testing::MockNats
      else
        Polyn::Nats
      end
    end

    def add_headers(headers, event)
      Polyn::Tracing.trace_header(headers)
      # Ensure accidental message duplication doesn't happen
      # https://docs.nats.io/using-nats/developer/develop_jetstream/model_deep_dive#message-deduplication
      { "Nats-Msg-Id" => event.id }.merge(headers)
    end
  end
end
