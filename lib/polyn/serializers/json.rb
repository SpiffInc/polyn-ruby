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
require "open-uri"
require "json_schemer"

module Polyn
  module Serializers
    ##
    # Handles serializing and deserializing data to and from JSON.
    class Json < Base
      DRAFT_URL   = "http://json-schema.org/draft-07/schema#"
      SCHEMA_URL  = "https://raw.githubusercontent.com/cloudevents/spec/v1.0.1/spec.json"
      FILE_SCHEME = "file"

      REQUIRED_PROPERTIES = %w[
        id
        type
        source
        specversion
        datacontenttype
        time
        data
      ].freeze

      def initialize(options = nil)
        super
        @schema_prefix     = options.fetch(:schema_prefix)
        @cached_validators = {}
      end

      def serialize(event)
        validate_event(event)

        JSON.dump(event.to_h)
      end

      def deserialize(data)
        hash = Utils::Hash.deep_symbolize_keys(JSON.parse(data))

        event                 = Event.new(hash)
        event.datacontenttype = "application/json"

        validate_event(event)

        event
      end

      private

      attr_reader :cached_validators, :schema_prefix

      def validate_event(event)
        puts schema_template(event)
        schema = cached_validators[event.type] ||= JSONSchemer.schema(
          schema_template(event),
          ref_resolver: proc { |ref| resolve_ref(ref) },
        )

        validation = schema.validate(event.to_h)

        raise Errors::ValidationError, validation.to_a.first["details"] if validation.any?
      end

      def schema_template(event)
        {
          "$schema"    => DRAFT_URL,
          "$id"        => SCHEMA_URL,
          "properties" => {
            "datacontenttype" => {
              "type" => "string",
            },
            "data"            => {
              "$ref" => "#{schema_prefix}/#{event.type}.json",
            },
          },
          "required"   => REQUIRED_PROPERTIES
        }
      end

      def resolve_ref(ref)
        if ref.scheme == FILE_SCHEME
          JSON.parse(File.read(ref.path))
        else
          JSON.parse(Net::HTTP.get(ref))
        end
      end
    end
  end
end
