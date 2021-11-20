# frozen_string_literal: true

module Polyn
  module Utils
    module String
      def self.to_camel_case(str)
        str    = str.split("_").map(&:capitalize).join
        str[0] = str[0].downcase
        str
      end

      def self.to_snake_case(str)
        str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
           .gsub(/([a-z\d])([A-Z])/, '\1_\2')
           .tr("-", "_")
           .downcase
      end
    end
  end
end
