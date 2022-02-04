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
    # Exception handlers are used to handle exceptions that occur wihthin a service.
    class Base
      def initialize(options = {})
        @options = options
      end

      ##
      # This method is called when an exception occurs within a service that is not related to
      # receiving or publishing events.
      def handle_exception(_exception)
        raise NotImplementedError,
          "You must implement the handle_exception method in your exception handler."
      end

      ##
      # This method is called when an exception occurs within a service that is related to receiving
      # events.
      def handle_receive_event_exception(_exception)
        raise NotImplementedError,
          "You must implement the handle_receive_event_exception method in your exception handler."
      end

      ##
      # This method is called when an exception occurs within a service that is related to publishing
      # events.
      def handle_publish_event_exception(_exception)
        raise NotImplementedError,
          "You must implement the handle_publish_event_exception method in your exception handler."
      end

      private

      attr_reader :options
    end
  end
end
