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
      case config
      when Hash
        transporter_config = config
        config             = transporter_config[:type]
      when Symbol, String
        transporter_config = { type: config }
      else
        raise ArgumentError, "Invalid transporter configuration: #{config.inspect}"
      end

      case config
      when Transporters::Base
        transporter_config
      when :internal || "internal"
        require_relative "./transporters/internal"
        Transporters::Internal
      when :pubsub || "pubsub"
        require_relative "./transporters/pubsub"
        Transporters::Pubsub
      else
        raise ArgumentError, "Unknown transporter: #{name}"
      end
    end
  end
end
