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

require_relative "base"

require "json-schema"

module Polyn
  module Validators
    ##
    # Validates the payload against a JSON Schema.
    class JsonSchema < Base
      ##
      # @param config [Hash] the JSON Schema validator config.
      def initialize(config)
        super()
        raise ArgumentError, "config must define a prefix" unless config.key?(:prefix)

        @prefix = config.delete(:prefix)
        @config = config
      end

      def validate(event, data)
        schema_location = File.join(prefix, "#{event}.json")
        JSON::Validator.fully_validate(schema_location, data, config)
      end

      private

      attr_reader :prefix, :config
    end
  end
end
