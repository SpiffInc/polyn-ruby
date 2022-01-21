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

require "spec_helper"

RSpec.describe "Internal Transporter with JSON Serializer" do
  let(:calc) do
    Class.new(Polyn::Service) do
      def self.result
        @result ||= Concurrent::IVar.new
      end

      name "calc"

      event "calc.mult", :mult
      event "calc.div", :div

      def mult(ctx)
        self.class.result.set(ctx.data[:a] * ctx.data[:b])
      end
    end
  end

  subject do
    Polyn.start(
      name:            "test",
      transporter:     :internal,
      serializer:      :json,
      service_manager: {
        services: [calc],
      },
    )
  end

  describe "publishing and subscribing" do
    it "should publish and subscribe" do
      subject
      Polyn.publish("calc.mult", a: 2, b: 3)

      res = calc.result.wait(1)

      expect(res.value).to eq(6)
    end
  end
end
