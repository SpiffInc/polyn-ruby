# frozen_string_literal: true

# Copyright 2021-2022 Spiff, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Polyn
  ##
  # Represents an event. Events follow the [Cloudevents](https://github.com/cloudevents)
  # specification.
  class Event
    CLOUD_EVENT_VERSION = "1.0"

    class UnsupportedVersionError < Errors::Error; end

    ##
    # @return [String] the cloud event version
    attr_reader :specversion

    ##
    # @return [String] event id
    attr_reader :id

    ##
    # @return [String] event type
    attr_reader :type

    ##
    # @return [String] event source
    attr_reader :source

    ##
    # @return [String] time of event creation
    attr_reader :time

    ##
    # @return [String] the data content type
    attr_accessor :datacontenttype

    ##
    # @return [String] the data
    attr_reader :data

    ##
    # @return [Array] Previous events that led to this one
    attr_reader :polyntrace

    ##
    # @return [Hash] Represents the information about the client that published the event
    # as well as additional metadata
    attr_reader :polyndata

    def initialize(hash)
      @specversion = hash.key?(:specversion) ? hash[:specversion] : "1.0"

      unless Gem::Dependency.new("", "~> #{CLOUD_EVENT_VERSION}").match?("", @specversion)
        raise UnsupportedVersionError, "Unsupported version: '#{hash[:specversion]}'"
      end

      @id              = hash.fetch(:id, SecureRandom.uuid)
      @type            = self.class.full_type(hash.fetch(:type))
      @source          = self.class.full_source(hash[:source])
      @time            = hash.fetch(:time, Time.now.utc.iso8601)
      @data            = hash.fetch(:data)
      @datacontenttype = hash.fetch(:datacontenttype, "application/json")
      @polyndata       = {
        clientlang:        "ruby",
        clientlangversion: RUBY_VERSION,
        clientversion:     Polyn::VERSION,
      }
    end

    def to_h
      {
        "specversion"     => specversion,
        "id"              => id,
        "type"            => type,
        "source"          => source,
        "time"            => time,
        "data"            => Utils::Hash.deep_stringify_keys(data),
        "datacontenttype" => datacontenttype,
        "polyndata"       => Utils::Hash.deep_stringify_keys(polyndata),
      }
    end

    ##
    # Get the Event `source` prefixed with reverse domain name
    def self.full_source(source = nil)
      root    = Polyn.configuration.source_root
      parts   = [domain, root]
      combine = lambda do |items|
        items.map { |part| Polyn::Naming.dot_to_colon(part) }.join(":")
      end
      name    = combine.call(parts)

      if source
        Polyn::Naming.validate_source_name!(source)
        source = source.gsub(/(#{name}){1}:?/, "")
        parts << source unless source.empty?
      end

      combine.call(parts)
    end

    ##
    # Get the Event `type` prefixed with reverse domain name
    def self.full_type(type)
      Polyn::Naming.validate_event_type!(type)
      "#{domain}.#{Polyn::Naming.trim_domain_prefix(type)}"
    end

    def self.domain
      Polyn.configuration.domain
    end
  end
end
