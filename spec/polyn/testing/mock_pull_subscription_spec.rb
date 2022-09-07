# frozen_string_literal: true

require "spec_helper"
require "polyn/testing/mock_nats"

RSpec.describe Polyn::Testing::MockPullSubscription do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:stream) { "MOCK_PULL_SUBSCRIPTION_TEST_STREAM" }
  let(:consumer) { "MOCK_PULL_SUBSCRIPTION_CONSUMER" }
  let(:mock_nats) do
    Polyn::Testing::MockNats.new(nats)
  end

  subject do
    described_class.new(mock_nats, subject: "mock_psub.foo",
      consumer_name: consumer)
  end

  before(:each) do
    js.add_stream(name: stream, subjects: ["mock_psub.*"])
    js.add_consumer(stream, durable_name: consumer)
  end

  after(:each) do
    js.delete_stream(stream)
  end

  describe "#fetch" do
    it "gets published message that matches" do
      mock_nats.publish("mock_psub.foo", "bar")
      msgs = subject.fetch
      expect(msgs.length).to eq(1)
      expect(msgs[0].data).to eq("bar")
    end

    it "cursor moves up on 2nd call" do
      mock_nats.publish("mock_psub.foo", "bar")
      subject.fetch
      msgs = subject.fetch
      expect(msgs.length).to eq(0)
    end

    it "can fetch multiple" do
      mock_nats.publish("mock_psub.foo", "bar")
      mock_nats.publish("mock_psub.foo", "baz")
      msgs = subject.fetch(2)
      expect(msgs.length).to eq(2)
      expect(msgs[0].data).to eq("bar")
      expect(msgs[1].data).to eq("baz")
    end

    it "subsequent multiple fetch can be empty" do
      mock_nats.publish("mock_psub.foo", "bar")
      mock_nats.publish("mock_psub.foo", "baz")
      subject.fetch(2)
      msgs = subject.fetch(2)
      expect(msgs.length).to eq(0)
    end

    it "new published messages come in" do
      mock_nats.publish("mock_psub.foo", "bar")
      subject.fetch
      mock_nats.publish("mock_psub.foo", "baz")
      msgs = subject.fetch
      expect(msgs.length).to eq(1)
      expect(msgs[0].data).to eq("baz")
    end

    it "asking for more than exist is ok" do
      mock_nats.publish("mock_psub.foo", "bar")
      msgs = subject.fetch(10)
      expect(msgs.length).to eq(1)
      expect(msgs[0].data).to eq("bar")
    end

    it "asking for more than exist and puts cursor at the end" do
      mock_nats.publish("mock_psub.foo", "bar")
      subject.fetch(10)
      mock_nats.publish("mock_psub.foo", "baz")
      msgs = subject.fetch(10)
      expect(msgs.length).to eq(1)
      expect(msgs[0].data).to eq("baz")
    end
  end
end
