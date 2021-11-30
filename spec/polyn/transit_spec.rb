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

RSpec.describe Polyn::Transit do
  let(:service_manager) { instance_double(Polyn::ServiceManager) }
  let(:transporter) { subject.instance_variable_get(:@transporter) }



  subject do
    Polyn::Transit.new(
      service_manager,
      origin:      "origin",
      transporter: :internal,
    )
  end

  before :each do
    allow(Polyn::Message).to receive(:new).and_return(message)
    allow(Polyn::Transporters::Internal).to receive(:new).and_return(transporter)
  end

  describe "#publish" do
    let(:message) { instance_double(Polyn::Message, for_transit: message_for_transit) }
    let(:message_for_transit) { double("MessageForTransit") }

    let(:serializer) { subject.instance_variable_get(:@serializer) }
    let(:serialized_message) { double("SerializedMessage") }

    it "should publish the serialized data" do
      expect(serializer).to receive(:serialize).with(message_for_transit).and_return(serialized_message)
      expect(transporter).to receive(:<<).with([:publish, "foo", serialized_message])

      subject.publish("foo", { foo: :bar })
    end
  end
end
