# frozen_string_literal: true

module Polyn
  module Utils
    module Hash
      ##
      # Deep symbolize keys of a hash.
      def self.deep_symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          value       = deep_symbolize_keys(value) if value.is_a? Hash
          result[begin
            key.to_sym
          rescue StandardError
            key
          end || key] = value
        end
      end

      ##
      # Deep stringifies keys
      def self.deep_stringify_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          value       = deep_stringify_keys(value) if value.is_a? Hash
          result[begin
            key.to_s
          rescue StandardError
            key
          end || key] = value
        end
      end

      ##
      # Deep camelize keys
      def self.deep_camelize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          value       = deep_camelize_keys(value) if value.is_a? Hash
          result[begin
            Utils::String.camelize(key.to_s)
          rescue StandardError
            key
          end || key] = value
        end
      end
    end
  end
end
