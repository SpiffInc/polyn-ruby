# frozen_string_literal: true

require_relative "../lib/polyn"

class Counter < Polyn::Service
  def initialize(initial_value = 0)
    super()
    @value = initial_value
  end
end

Polyn::Supervisor.new(
  transporter: Polyn::Transporters::Fake.new,
  services:    [Counter],
).start
