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
  subject do
    Polyn::Transit.spawn(service_manager, origin: "origin", transporter: :internal)
  end


  let(:ev) { Concurrent::Event.new }
  let(:service_manager) { instance_double(Polyn::ServiceManager) }
  let(:transporter) { double("InternalTransporter") }
  let(:serializer) { instance_double(Polyn::Serializers::Json) }


  before :each do
    allow(Polyn::Message).to receive(:new).and_return(message)
    allow(Polyn::Transporters::Internal).to receive(:spawn).and_return(transporter)
    allow(Polyn::Serializers::Json).to receive(:new).and_return(serializer)
  end

  describe "#publish" do
    let(:message) { instance_double(Polyn::Message, for_transit: message_for_transit) }

    let(:message_for_transit) { double("MessageForTransit") }
    let(:serialized_message) { double("SerializedMessage") }

    it "should publish the serialized data" do
      expect(serializer).to receive(:serialize).with(message.for_transit).and_return(serialized_message)
      expect(transporter).to receive(:<<).with([:publish, "foo", serialized_message]) { ev.set }

      subject << [:publish, "foo", message]

      ev.wait(1)
    end
  end

  describe ":receive message" do


    let(:context) { instance_double(Polyn::Context) }
    let(:payload) { { bar: "baz" } }
    let(:json) { payload.to_json }

    it "should send the deserializes the message and sends the context to the service_manager" do
      expect(Polyn::Context).to receive(:new).with(**{ payload: payload }).and_return(context)
      expect(service_manager).to receive(:receive) { ev.set }

      subject << [:receive, "test", json]

      ev.wait(1)
    end
  end
end
