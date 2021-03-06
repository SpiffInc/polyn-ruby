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
    Polyn::Transit.spawn(
      service_manager,
      origin:      "origin",
      transporter: { type: :internal },
      serializer:  { type:          :json,
                     schema_prefix: "file://#{File.expand_path('../fixtures', __dir__)}" },
    )
  end

  let(:service_manager) { Polyn::ServiceManager.spawn(services: []) }

  let(:ev) { Concurrent::Event.new }
  describe "#publish" do
    let(:event) do
      Polyn::Event.new({
        source: "com.test.my_app",
        type:   "calc.mult",
        data:   { a: 1, b: 2 },
      })
    end

    it "should publish the serialized data" do
      expect_any_instance_of(Polyn::Transporters::Internal::Wrapper).to receive(:publish!).with(
        "calc.mult", instance_of(String)
      ) do |_, _, serialized|
        expect(JSON.parse(serialized)).to eq({
          "type"            => "calc.mult",
          "data"            => { "a" => 1, "b" => 2 },
          "id"              => event.id,
          "source"          => "com.test.my_app",
          "specversion"     => "1.0",
          "time"            => event.time,
          "datacontenttype" => "application/json",
        })

        ev.set
      end

      subject.publish(event)

      ev.wait(1)
    end
  end

  describe ":receive message" do
    let(:event_json) do
      {
        source:          "com.test",
        type:            "calc.mult",
        data:            {
          a: 1,
          b: 2,
        },
        time:            Time.now.utc.iso8601,
        datacontenttype: "application/json",
      }.to_json
    end

    let(:envelope) do
      Polyn::Transporters::Internal::Envelope.new("calc.mult", event_json)
    end

    subject do
      Polyn::Transit.spawn(
        service_manager,
        origin:      "origin",
        transporter: { type: :internal },
        serializer:  { type:          :json,
                       schema_prefix: "file://#{File.expand_path('../fixtures', __dir__)}" },
      ).instance_variable_get(:@actor)
    end

    it "should send the deserializes the message and sends the context to the service_manager" do
      expect(service_manager).to receive(:<<).with([:receive,
                                                    instance_of(Polyn::Context)]) do |_, context|
        expect(context.envelope).to eq(envelope)
        expect(context.event).to be_an_instance_of(Polyn::Event)

        ev.set
      end

      subject << [:receive, envelope]

      ev.wait(1)
    end
  end
end
