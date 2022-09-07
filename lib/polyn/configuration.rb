# frozen_string_literal: true

module Polyn
  ##
  # Configuration data for Polyn
  class Configuration
    def initialize
      @domain      = nil
      @source_root = nil
      @polyn_env   = ENV["POLYN_ENV"] || ENV["RAILS_ENV"] || "development"
    end

    attr_reader :polyn_env

    def domain
      @domain ||= Polyn::Naming.validate_domain_name!(@domain)
    end

    def domain=(name)
      Polyn::Naming.validate_domain_name!(name)
      @domain = name
    end

    def source_root
      @source_root ||= Polyn::Naming.validate_source_root!(@source_root)
    end

    def source_root=(name)
      Polyn::Naming.validate_source_root!(name)
      @source_root = name
    end
  end
end
