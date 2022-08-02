# frozen_string_literal: true

require_relative "error"

module Polyn
  module Errors
    ##
    # Raised when there are problems with the schema aside from validation
    class SchemaError < Error
    end
  end
end
