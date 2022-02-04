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

RSpec.describe Polyn::Application do
  subject do
    described_class.new(
      name:          "my_app",
      source_prefix: "com.test",
    )
  end

  describe "#publish" do
    it "publishes an event to the transit" do
      expect_any_instance_of(Polyn::Transit::Wrapper).to receive(:publish).with(instance_of(Polyn::Event)) do |_, event|
        expect(event.source).to eq("com.test.my_app")
        expect(event.type).to eq("calc.mult")
        expect(event.data).to eq({ a: 1, b: 2 })
      end

      subject.publish("calc.mult", { a: 1, b: 2 })
    end
  end
end
