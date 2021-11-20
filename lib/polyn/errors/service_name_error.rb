# frozen_string_literal: true

module Polyn
  module Errors
    ##
    # Raised when there is an error with the service name.
    class ServiceNameError < Error
      ##
      # @param [String] service_name The service name.
      def initialize(service_name)
        super("Service name '#{service_name}' is invalid.")
      end
    end
  end
end
