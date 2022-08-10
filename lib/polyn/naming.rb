# frozen_string_literal: true

module Polyn
  ##
  # Methods for formatting and validating names of fields
  class Naming
    ##
    # Convert a dot separated name into a colon separated name
    def self.dot_to_colon(str)
      str.gsub(".", ":")
    end

    def self.dot_to_underscore(name)
      name.gsub(".", "_")
    end

    def self.colon_to_underscore(name)
      name.gsub(":", "_")
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

    ##
    # Create a consumer name from a source and type
    def self.consumer_name(type, source = nil)
      validate_event_type!(type)
      type = trim_domain_prefix(type)
      type = dot_to_underscore(type)

      root = Polyn.configuration.source_root
      root = dot_to_underscore(root)
      root = colon_to_underscore(root)

      if source
        validate_source_name!(source)
        source = dot_to_underscore(source)
        source = colon_to_underscore(source)
        [root, source, type].join("_")
      else
        [root, type].join("_")
      end
    end

    def self.domain
      Polyn.configuration.domain
    end
  end
end
