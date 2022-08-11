# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::PullSubscriber do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:store_name) { "PULL_SUBSCRIBER_TEST_STORE" }
  let(:stream_name) { "PULL_SUBSCRIBER_TEST_STREAM" }

  before(:each) do
    js.add_stream(name: stream_name, subjects: ["calc.add.v1"])
    js.add_consumer(stream_name, durable_name: "user_backend_calc_add_v1")
    js.create_key_value(bucket: store_name)

    add_schema("calc.add.v1", {
      "type"       => "object",
      "properties" => {
        "data" => {
          "type"       => "object",
          "properties" => {
            "a" => { "type" => "integer" },
            "b" => { "type" => "integer" },
          },
        },
      },
    })
  end

  after(:each) do
    js.delete_stream(stream_name)
    js.delete_key_value(store_name)
  end

  subject do
    described_class.new({ nats: nats, store_name: store_name, type: "calc.add.v1" })
  end

  describe "#fetch" do
    it "turns msg body into event" do
      Polyn.publish(nats, "calc.add.v1", { a: 1, b: 2 }, store_name: store_name)
      msgs = subject.fetch
      msg  = msgs[0]
      expect(msg.data).to be_a(Polyn::Event)
      expect(msg.data.data[:a]).to eq(1)
      expect(msg.data.data[:b]).to eq(2)
    end

    it "invalid message sends ACKTERM" do
      # Publishing with vanilla nats instead of polyn
      nats.publish("calc.add.v1", JSON.generate({ a: "1", b: "2" }))
      expect do
        subject.fetch
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  def add_schema(type, schema)
    Polyn::SchemaStore.save(nats, type, schema, name: store_name)
  end
end
