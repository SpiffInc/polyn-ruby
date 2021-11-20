# frozen_string_literal: true

module Polyn
  module Serializers
    class Base
      def initialize(options = {})
        @options = options
      end

      def serialize(data)
        raise NotImplementedError
      end

      def deserialize(data)
        raise NotImplementedError
      end
    end
  end
end
