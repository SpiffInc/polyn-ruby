# frozen_string_literal: true

module Polyn
  module Serializers
    class Json < Base
      def serialize(data)
        JSON.dump(data)
      end

      def deserialize(data)
        JSON.parse(data)
      end
    end
  end
end
