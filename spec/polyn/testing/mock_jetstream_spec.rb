# frozen_string_literal: true

require "spec_helper"
require "polyn/testing/mock_jetstream"

RSpec.describe Polyn::Testing::MockJetStream do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }

  subject do
    described_class.new(nats)
  end

  it "#consumer_info looks up consumer name from nats" do
    js.add_stream(name: "MOCK_JS_TEST_STREAM", subjects: ["mock_js_subject"])
    js.add_consumer("MOCK_JS_TEST_STREAM", durable_name: "MOCK_JS_CONSUMER")

    expect(subject.consumer_info("MOCK_JS_TEST_STREAM",
      "MOCK_JS_CONSUMER")).to be_instance_of(NATS::JetStream::API::ConsumerInfo)

    js.delete_stream("MOCK_JS_TEST_STREAM")
  end
end
