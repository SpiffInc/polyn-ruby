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
require_relative "polyn/application"
require_relative "polyn/validators"
require_relative "polyn/service"
require_relative "polyn/errors"
require_relative "polyn/transporters"
require_relative "polyn/utils"
require_relative "polyn/serializers"
require_relative "polyn/message"


##
# Polyn is a Reactive service framework.
module Polyn
  ##
  # Starts the application with the provided configuration.
  #
  # @param config [Hash] The configuration for the application.
  # @options config [$stdout|Hash] :log_options The log options. If no options are
  #   provided, $stdout will be used.
  def self.start(config = {})
    configure_logger(config.fetch(:log_options, $stdout))
    @application = Application.spawn(config)
  end


  ##
  # Publishes a message on the Polyn network.
  #
  # @param topic [String] The topic to publish the message on.
  # @param payload [Hash] The payload to publish.
  def self.publish(topic, payload)
    @application << [:publish, topic, payload]
  end

  def self.configure_logger(log_options)
    if log_options == $stdout
      SemanticLogger.add_appender(io: $stdout, formatter: :color)
      SemanticLogger.default_level = :trace
    end

    Concurrent.global_logger = Utils::ConcurrentLogger.new
  end
end