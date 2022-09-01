# frozen_string_literal: true

require "spec_helper"
require "polyn/testing/mock_nats"

RSpec.describe Polyn::Testing::MockNats do
  subject do
    described_class.new(nil)
  end

  it "receives subscribed messages" do
    msgs = []

    subject.subscribe("foo.bar.v1") do |msg|
      msgs << msg
    end

    subject.publish("foo.bar.v1", "data")

    expect(msgs.length).to eq(1)
    expect(msgs[0].subject).to eq("foo.bar.v1")
    expect(msgs[0].data).to eq("data")
  end

  it "receives subscribed wildcard messages" do
    msgs = []

    subject.subscribe("foo.bar.*") do |msg|
      msgs << msg
    end

    subject.publish("foo.bar.v1", "data")

    expect(msgs.length).to eq(1)
    expect(msgs[0].subject).to eq("foo.bar.v1")
    expect(msgs[0].data).to eq("data")
  end

  it "gets a jetstream instance" do
    expect(subject.jetstream).to be_instance_of(Polyn::Testing::MockJetStream)
  end
end
