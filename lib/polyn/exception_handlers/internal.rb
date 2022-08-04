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
  module ExceptionHandlers
    ##
    # A basic exception handler that simply logs the exception to the console.
    class Internal < Base
      def handle_exception(actor, exception, level = :error)
        actor.logger.send(
          level,
          exception.message,
          message:   exception.message,
          backtrace: exception.backtrace,
          actor:     actor.core.path,
        )
      end

      def handle_publish_event_exception(actor, event, exception)
        actor.logger.error(
          message:   exception.message,
          backtrace: exception.backtrace,
          actor:     actor.core.path,
          event:     event.to_h,
        )
      end

      def handle_receive_event_exception(actor, event, exception)
        actor.logger.error(
          message:   exception.message,
          backtrace: exception.backtrace,
          actor:     actor.core.path,
          event:     event.to_h,
        )
      end
    end
  end
end
