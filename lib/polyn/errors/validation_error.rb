# frozen_string_literal: true

require_relative "error"

module Polyn
  module Errors
    ##
    # Raised when a part of the schema is invalid
    class ValidationError < Error
    end
  end
end
