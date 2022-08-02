# frozen_string_literal: true

module Polyn
  ##
  # Configuration data for Polyn
  class Configuration
    attr_accessor :domain, :source_root

    def initialize
      @domain      = nil
      @source_root = nil
    end
  end
end
