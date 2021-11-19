# frozen_string_literal: true

require_relative "../lib/polyn"

class Counter < Polyn::Service
  event "increment", :increment

  def initialize(initial_value = 0)
    super()
    @value = initial_value
  end

  def increment
    @value += 1
  end
end

Polyn::Supervisor.start(
  services: [Counter]
).join
