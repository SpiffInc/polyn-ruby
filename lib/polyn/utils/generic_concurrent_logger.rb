# frozen_string_literal: true

module Polyn
  module Utils
    ##
    # @private
    class GenericConcurrentLoggger
      LEVELS = %i[debug info warn error fatal].freeze

      def initialize(logger)
        @logger = logger
      end

      def call(level, *args)
        logger.public_send(LEVELS[level], args.join(" ")) unless args.last.nil?
      end

      private

      attr_reader :logger
    end
  end
end
