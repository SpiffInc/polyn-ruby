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

module Polyn
  module Utils
    ##
    # Utilities for hash manipulation.
    module Hash
      ##
      # Deep symbolize keys of a hash.
      #
      # @param hash [::Hash] The hash to symbolize.
      #
      # @return [::Hash] The symbolized hash.
      def self.deep_symbolize_keys(hash)
        return hash.map { |item| deep_symbolize_keys(item) } if hash.is_a?(::Array)
        return hash unless hash.is_a?(::Hash)

        hash.each_with_object({}) do |(key, value), result|
          result[key.to_sym] = deep_symbolize_keys(value)
        end
      end

      ##
      # Deep stringifies keys
      #
      # @param hash [::Hash] The hash to stringify.
      #
      # @return [::Hash] The stringified hash.
      def self.deep_stringify_keys(hash)
        return hash.map { |item| deep_stringify_keys(item) } if hash.is_a?(::Array)
        return hash unless hash.is_a?(::Hash)

        hash.each_with_object({}) do |(key, value), result|
          result[key.to_s] = deep_stringify_keys(value)
        end
      end

      ##
      # Deep camelize keys
      #
      # @param hash [::Hash] The hash to camelize.
      #
      # @return [::Hash] The camelized hash.
      def self.deep_camelize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[String.to_camel_case(key)] =
            value.is_a?(::Hash) ? deep_camelize_keys(value) : value
        end
      end

      ##
      # Deep snake cases keys
      #
      # @param hash [::Hash] The hash to snake case.
      #
      # @return [::Hash] The snake cased hash.
      def self.deep_snake_case_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[String.to_snake_case(key.to_s)] =
            value.is_a?(::Hash) ? deep_snake_case_keys(value) : value
        end
      end
    end
  end
end
