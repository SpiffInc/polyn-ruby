# frozen_string_literal: true

require_relative "errors/configuration_error"
require_relative "errors/validation_error"

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
    def self.validate_domain_name!(name)
      if name.is_a?(String) && name.match?(/\A[a-z0-9]+(?:(?:\.|:)[a-z0-9]+)*\z/)
        name
      else
        raise Polyn::Errors::ConfigurationError,
          "You must configure the `domain` for Polyn. It must be lowercase, alphanumeric and dot/colon separated, got #{name}"
      end
    end

    ##
    # Validate the `source` name
    def self.validate_source_name(name)
      if name.is_a?(String) && name.match?(/\A[a-z0-9]+(?:(?:\.|:)[a-z0-9]+)*\z/)
        true
      else
        "Event source must be lowercase, alphanumeric and dot/colon separated, got #{name}"
      end
    end

    ##
    # Validate the `source` name and raise if invalid
    def self.validate_source_name!(name)
      message = validate_source_name(name)
      if message == true
        name
      else
        raise Polyn::Errors::ValidationError, message
      end
    end

    ##
    # Validate that the configured `source_root` is in the correct format
    def self.validate_source_root!(name)
      message = validate_source_name(name)
      if message == true
        name
      else
        raise Polyn::Errors::ConfigurationError,
          "You must configure the `source_root` for Polyn. #{message}"
      end
    end

    ##
    # Validate the event type
    def self.validate_event_type!(name)
      if name.is_a?(String) && name.match?(/\A[a-z0-9]+(?:\.[a-z0-9]+)*\z/)
        name
      else
        raise Polyn::Errors::ValidationError,
          "Event types must be lowercase, alphanumeric and dot separated"
      end
    end

    ##
    # Remove the `domain` name from the beginning of a string
    def self.trim_domain_prefix(str)
      str = str.sub("#{domain}.", "")
      str.sub("#{dot_to_colon(domain)}:", "")
    end

    def self.domain
      Polyn.configuration.domain
    end
  end
end
