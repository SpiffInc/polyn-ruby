# frozen_string_literal: true

require "spec_helper"
require "polyn/testing/mock_nats"

RSpec.describe Polyn::Testing::MockJetStream do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:stream) { "MOCK_JS_TEST_STREAM" }
  let(:consumer) { "MOCK_JS_CONSUMER" }

  subject do
    described_class.new(Polyn::Testing::MockNats.new(nats))
  end

  before(:each) do
    js.add_stream(name: stream, subjects: ["mock_js.*"])
    js.add_consumer(stream, durable_name: consumer)
  end

  after(:each) do
    js.delete_stream(stream)
  end

  it "#consumer_info looks up consumer name from nats" do
    expect(subject.consumer_info(stream,
      consumer)).to be_instance_of(NATS::JetStream::API::ConsumerInfo)
  end

  it "#find_stream_name_by_subject looks up stream name from nats" do
    expect(subject.find_stream_name_by_subject("mock_js.foo")).to eq(stream)
  end

  it "#pull_subscribe returns a pull subscription" do
    expect(subject.pull_subscribe("foo",
      "bar")).to be_instance_of(Polyn::Testing::MockPullSubscription)
  end
end
