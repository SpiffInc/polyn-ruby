# frozen_string_literal: true

require_relative "error"

module Polyn
  module Errors
    ##
    # Raised when there is an error with Polyn configuration
    class ConfigurationError < Error
    end
  end
end
