# frozen_string_literal: true

module Polyn
  module Errors
    ##
    # Polyn base error class.
    class Error < StandardError
      def initialize(message = nil, code: 500)
        super(message)
      end
    end
  end
end
