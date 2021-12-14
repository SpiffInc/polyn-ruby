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
require_relative "../../lib/polyn/validators/json_schema"

RSpec.describe Polyn::Application do
  let(:service_manager) { double(Polyn::ServiceManager) }
  let(:transit) { double(Polyn::Transit) }

  subject do
    described_class.new(
      name:      "MyApp",
      validator: Polyn::Validators::JsonSchema.new(
        prefix: File.expand_path("../fixtures", __dir__),
        file:   true,
      ),
    )
  end

  describe "#initialize" do
    it "requires and sets the name" do
      expect(subject.name).to eq("MyApp")
    end

    it "sets up the service manager" do
      expect(Polyn::ServiceManager).to receive(:spawn).and_return(service_manager)

      subject
    end

    it "sets up the transit" do
      expect(Polyn::Transit).to receive(:spawn).and_return(service_manager)

      subject
    end
  end

  describe "#publish" do
    context "invalid payload" do
      it "raises Polyn::Errors::ValidationError" do
        expect do
          subject.publish("calc.mult", { wrong: "payload" })
        end.to raise_error(Polyn::Errors::PayloadValidationError)
      end
    end

    context "snake cased keys" do
      it "camel cases the keys before validation" do
        expect do
          subject.publish("calc.mult", { a: 1, b: 2 })
        end.to_not raise_exception
      end
    end
  end
end
