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

module Polyn
  module Serializers
    ##
    # Handles serializing and deserializing data to and from JSON.
    class Json
      def self.serialize!(nats, event, **opts)
        validate_event_type!(event)
        validate!(nats, event.to_h, opts)
      end

      def self.validate!(_nats, event, **_opts)
        validate_cloud_event(event)
      end

      def self.validate_event_type!(event)
        if event.instance_of?(Polyn::Event)
          event
        else
          raise Polyn::Errors::ValidationError,
            "Can only serialize `Polyn::Event` instances. got #{event}"
        end
      end

      def self.validate_cloud_event(event)
        cloud_event_schema = Polyn::CloudEvent.to_h
        schema             = JSONSchemer.schema(cloud_event_schema)
        results            = schema.validate(event).to_a
        puts results.class
        puts results.length
        puts results[0].keys
        puts "TYPE"
        puts results[0]["type"]
        puts "SCHEMA POINTER"
        puts results[0]["schema_pointer"]
        puts "DETAILS"
        puts results[0]["details"]
        puts "DATA POINTER"
        puts results[0]["data_pointer"]
      end

      # def validate_event(event)
      #   schema = cached_validators[event.type] ||= JSONSchemer.schema(
      #     schema_template(event),
      #     ref_resolver: proc { |ref| resolve_ref(ref) },
      #   )

      #   validation = schema.validate(event.to_h)

      #   raise Errors::ValidationError, validation.to_a if validation.any?
      # end
    end
  end
end
