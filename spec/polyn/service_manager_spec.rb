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
  describe ":receive message" do
    let(:context) { instance_double(Polyn::Context) }
    let(:service_1) { class_double(Polyn::Service) }
    let(:service_2) { class_double(Polyn::Service) }
    let(:ev) { Concurrent::Event.new }

    subject { Polyn::ServiceManager.spawn([service_1, service_2]) }

    it "should call #receive on the service" do
      expect(service_1).to receive(:receive).with("test", context)
      expect(service_2).to receive(:receive).with("test", context) { ev.set }

      subject << [:receive, "test", context]

      ev.wait(1)
    end
  end
end
