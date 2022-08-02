# frozen_string_literal: true

require_relative "errors/configuration_error"

module Polyn
  ##
  # Methods for formatting and validating names of fields
  class Naming
    def self.validate_domain_name(name)
      if name.is_a?(String) && name.match?(/\A[a-z0-9]+(?:(?:\.|:)[a-z0-9]+)*\z/)
        name
      else
        raise Polyn::Errors::ConfigurationError,
          "You must configure the `domain` for Polyn. It must be lowercase, alphanumeric and dot/colon separated, got #{name}"
      end
    end
  end
end
