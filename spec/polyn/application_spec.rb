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

require "spec_helper"

RSpec.describe Polyn::Application do
  let(:service_manager) { double(Polyn::ServiceManager) }
  let(:transit) { double(Polyn::Transit) }

  describe "#initialize" do
    it "requires and sets the name" do
      app = described_class.new(name: "MyApp")
      expect(app.name).to eq("MyApp")
    end

    it "sets up the service manager" do
      expect(Polyn::ServiceManager).to receive(:spawn).and_return(service_manager)

      described_class.new(name: "MyApp")
    end

    it "sets up the transit" do
      expect(Polyn::Transit).to receive(:spawn).and_return(service_manager)

      described_class.new(name: "MyApp")
    end
  end

  describe "#publish" do
    it "passes the publish message to the transit actor" do
      expect(Polyn::Transit).to receive(:spawn).and_return(service_manager)
      expect(transit).to receive(:<<).with([:publish, "test", { foo: "bar" }])

      described_class.new(name: "MyApp").publish("test", { foo: "bar" })
    end
  end
end
