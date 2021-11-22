# frozen_string_literal: true

# Copyright 2021-2022 Jarod Reid
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

require "concurrent/actor"
require "semantic_logger"

require_relative "polyn/version"
require_relative "polyn/supervisor"
require_relative "polyn/service"
require_relative "polyn/errors"
require_relative "polyn/transporters"
require_relative "polyn/utils"
require_relative "polyn/serializers"


module Polyn
  def self.start(options = {})
    @supervisor = Supervisor.spawn(options)
    @running    = true

    Signal.trap("INT") do
      puts "Terminating..."
      shutdown
    end

    sleep 1 while @running
  end

  def self.wait
    puts "waiting"
    sleep 1 until @running
    puts "pone waiting"
  end

  def self.publish(topic, message)
    @supervisor << [:publish, topic, message]
  end
end