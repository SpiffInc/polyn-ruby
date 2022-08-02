# frozen_string_literal: true

require_relative "naming"

module Polyn
  ##
  # Configuration data for Polyn
  class Configuration
    def initialize
      @domain      = nil
      @source_root = nil
    end

    def domain
      @domain ||= Polyn::Naming.validate_domain_name(@domain)
    end

    def domain=(name)
      Polyn::Naming.validate_domain_name(@domain)
      @domain = name
    end
  end
end
