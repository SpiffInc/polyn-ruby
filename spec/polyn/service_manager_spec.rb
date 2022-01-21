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

RSpec.describe Polyn::ServiceManager do
  let(:service_1) { class_double(Polyn::Service) }
  let(:service_2) { class_double(Polyn::Service) }
  subject { Polyn::ServiceManager.spawn(services: [service_1, service_2]) }

  describe ":receive message" do
    let(:context) { instance_double(Polyn::Context) }

    let(:ev) { Concurrent::Event.new }


    it "should call #receive on the service" do
      expect(service_1).to receive(:receive).with(context)
      expect(service_2).to receive(:receive).with(context) { ev.set }

      subject << [:receive, context]

      ev.wait(1)
    end
  end

  describe "services" do
    it "should be capable of returning all services" do
      expect(subject.ask!(:services)).to eq([service_1, service_2])
    end
  end
end
