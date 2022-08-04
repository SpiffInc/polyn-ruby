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

require "json"
require "json_schemer"
require "polyn/cloud_event"
require "polyn/event"
require "polyn/naming"
require "polyn/schema_store"

module Polyn
  module Serializers
    ##
    # Handles serializing and deserializing data to and from JSON.
    class Json
      def self.serialize!(nats, event, **opts)
        validate_event_instance!(event)
        validate!(nats, event.to_h, opts)
      end

      def self.validate!(nats, event, **opts)
        validate_cloud_event!(event)
        validate_data!(nats, event, opts)
        JSON.generate(event)
      end

      def self.validate_event_instance!(event)
        if event.instance_of?(Polyn::Event)
          event
        else
          raise Polyn::Errors::ValidationError,
            "Can only serialize `Polyn::Event` instances. got #{event}"
        end
      end

      def self.validate_cloud_event!(event)
        cloud_event_schema = Polyn::CloudEvent.to_h
        validate_schema!(cloud_event_schema, event)
      end

      def self.validate_data!(nats, event, opts)
        type   = get_event_type!(event)
        schema = get_schema!(nats, type, opts)
        validate_schema!(schema, event)
      end

      def self.validate_schema!(schema, event)
        schema = JSONSchemer.schema(schema)
        errors = schema.validate(event).to_a
        errors = format_schema_errors(errors)
        unless errors.empty?
          raise Polyn::Errors::ValidationError, combined_error_message(event, errors)
        end
      end

      def self.get_event_type!(event)
        event["type"] || raise(Polyn::Errors::ValidationError,
          "Could not find a `type` in message #{event.inspect} \nEvery event must have a `type`")
        Polyn::Naming.trim_domain_prefix(event["type"])
      end

      def self.get_schema!(nats, type, **opts)
        Polyn::SchemaStore.get(nats, type, name: store_name(opts))
      end

      def self.format_schema_errors(errors)
        errors.map do |error|
          "Property: `#{error['data_pointer']}` - #{error['type']} - #{error['details']}"
        end
      end

      def self.combined_error_message(event, errors)
        [
          "Polyn event #{event['id']} from #{event['source']} is not valid",
          "Event data: #{event.inspect}",
        ].concat(errors).join("\n")
      end

      def self.store_name(**opts)
        opts.fetch(:store_name, Polyn::SchemaStore.store_name)
      end
    end
  end
end
