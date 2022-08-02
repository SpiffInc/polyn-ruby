# frozen_string_literal: true

require_relative "errors/configuration_error"

module Polyn
  ##
  # Methods for formatting and validating names of fields
  class Naming
    ##
    # Convert a dot separated name into a colon separated name
    def self.dot_to_colon(str)
      str.gsub(".", ":")
    end

    ##
    # Validate that the configured `domain` is in the correct format
    def self.validate_domain_name(name)
      if name.is_a?(String) && name.match?(/\A[a-z0-9]+(?:(?:\.|:)[a-z0-9]+)*\z/)
        name
      else
        raise Polyn::Errors::ConfigurationError,
          "You must configure the `domain` for Polyn. It must be lowercase, alphanumeric and dot/colon separated, got #{name}"
      end
    end

    ##
    # Validate that the configured `source_root` is in the correct format
    def self.validate_source_root(name)
      if name.is_a?(String) && name.match?(/\A[a-z0-9]+(?:(?:\.|:)[a-z0-9]+)*\z/)
        name
      else
        raise Polyn::Errors::ConfigurationError,
          "You must configure the `source_root` for Polyn. It must be lowercase, alphanumeric and dot/colon separated, got #{name}"
      end
    end
  end
end
