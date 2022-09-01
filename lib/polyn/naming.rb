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
      type = type.gsub(".", "_")

      root = Polyn.configuration.source_root
      root = root.gsub(".", "_")
      root = root.gsub(":", "_")

      if source
        validate_source_name!(source)
        source = source.gsub(".", "_")
        source = source.gsub(":", "_")
        [root, source, type].join("_")
      else
        [root, type].join("_")
      end
    end

    ##
    # Determine if a given subject matches a subscription pattern
    def self.subject_matches?(subject, pattern)
      separator         = "."

      pattern_tokens = pattern.split(separator).map { |token| build_subject_pattern_part(token) }
      pattern_tokens = pattern_tokens.join("\\#{separator}")
      subject.match?(Regexp.new(pattern_tokens))
    end

    def self.build_subject_pattern_part(token)
      single_wildcard   = "*"
      multiple_wildcard = ">"

      return "(\\w+)" if token == single_wildcard

      return "((\\w+\\.)*\\w)" if token == multiple_wildcard

      token
    end

    def self.domain
      Polyn.configuration.domain
    end
  end
end
