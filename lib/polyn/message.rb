# frozen_string_literal: true

module Polyn
  ##
  # Represents a Polyn message.
  class Message
    def initialize(message)
      @payload    = message
      @created_at = Time.utc.now
      @uuid       = SecureRandom.uuid
      @node_id    = Polyn::Supervisor.node_id
      @service    = Polyn::Service.current
    end
  end
end
