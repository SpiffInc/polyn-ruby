# frozen_string_literal: true

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

    def initialize(hash)
      @specversion = hash.has_key?(:specversion) ? hash[:specversion] : "1.0"
      if @specversion != CLOUD_EVENT_VERSION
        raise UnsupportedVersionError, "Unsupported version: '#{hash[:specversion]}'"
      end

      @id          = hash.fetch(:id, SecureRandom.uuid)
      @type        = hash.fetch(:type)
      @source      = hash.fetch(:source)
      @time        = hash.fetch(:time, Time.now.utc.iso8601)
      @data        = hash.fetch(:data)
    end
  end
end
