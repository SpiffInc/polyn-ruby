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

require_relative "../../../lib/polyn/transporters/pubsub"

RSpec.describe Polyn::Transporters::Pubsub do
  let(:transit) { double(Polyn::Transit) }
  let(:options) do
    {
      project_id:    "test-project",
      emulator_host: "localhost:8085",
    }
  end

  let(:ev) {Concurrent::Event.new}

  let(:pubsub_client) { Google::Cloud::Pubsub.new(**options) }

  subject { described_class.spawn(transit, options) }

  before :each do
    subject.connect!

    topic   = pubsub_client.topic("test-topic")
    topic ||= pubsub_client.create_topic("test-topic")

    subscription   = pubsub_client.subscription("test-topic")
    topic.subscribe("test-topic") unless subscription
  end

  after :each do
    subject.disconnect!

    pubsub_client.subscription("test-topic").delete
    pubsub_client.topic("test-topic").delete
  end

  describe("publish and subscribe") do
    it "should publish the provided message to the subscribed topic" do
      expect(transit).to receive(:<<).with([:receive, instance_of(described_class::Message)]) do |_, message|
        message.acknowledge
        ev.set
      end

      subject.subscribe!("test-topic")
      subject.publish!("test-topic", "test-message")

      ev.wait(5)
    end
  end
end
