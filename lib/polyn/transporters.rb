# frozen_string_literal: true

require_relative "transporters/base"
require_relative "transporters/internal"

module Polyn
  ##
  # Transporters provide the ability to communicate with an event bus.
  module Transporters
    ##
    # Instantiates and returns a new instance of a transporter based on the provided
    # configuration information.
    #
    # @param [String|Symbol|Hash|Transporters::Base] config The configuration information for the
    #   transporter.
    #
    # @return [Transporters::Base] The new transporter instance.
    def self.for(config)
      transporter_config = config.is_a?(Hash) ? config : {}
      case config
      when Transporters::Base
        transporter_config
      when :internal || "internal"
        Transporters::Internal
      else
        raise ArgumentError, "Unknown transporter: #{name}"
      end
    end
  end
end
