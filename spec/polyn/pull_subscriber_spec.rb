# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::PullSubscriber do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:store_name) { "PULL_SUBSCRIBER_TEST_STORE" }
  let(:stream_name) { "PULL_SUBSCRIBER_TEST_STREAM" }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:schema_store) do
    Polyn::SchemaStore.new(nats, name: store_name, schemas: {
      "calc.add.v1" => JSON.generate({
        "type" => "object",
        "properties": {
          "data" => {
            "type"       => "object",
            "properties" => {
              "a" => { "type" => "integer" },
              "b" => { "type" => "integer" },
            },
          },
        },
      }),
    })
  end
  let(:serializer) { Polyn::Serializers::Json.new(schema_store) }

  before(:each) do
    js.add_stream(name: stream_name, subjects: ["calc.add.v1"])
    js.add_consumer(stream_name, durable_name: "user_backend_calc_add_v1")
  end

  after(:each) do
    js.delete_stream(stream_name)
  end

  subject do
    described_class.new({ nats: nats, type: "calc.add.v1", serializer: serializer })
  end

  describe "#fetch" do
    it "turns msg body into event" do
      Polyn.connect(nats, store_name: store_name, schema_store: schema_store).publish(
        "calc.add.v1", { a: 1, b: 2 }
      )
      msgs = subject.fetch
      msg  = msgs[0]
      expect(msg.data).to be_a(Polyn::Event)
      expect(msg.data.data[:a]).to eq(1)
      expect(msg.data.data[:b]).to eq(2)

      # Tracing
      expect(spans.length).to eq(3)

      send_span    = spans.find { |span| span.name.include?("send") }
      receive_span = spans.find { |span| span.name.include?("receive") }
      process_span = spans.find { |span| span.name.include?("process") }

      expect(receive_span.name).to eq("calc.add.v1 receive")
      expect(receive_span.kind).to eq("CONSUMER")
      expect(receive_span.parent_span_id).to eq(send_span.span_id)
      expect(receive_span.links[0].span_context.span_id).to eq(process_span.span_id)
      expect(receive_span.attributes).to eq({
        "messaging.system"                     => "NATS",
        "messaging.destination"                => "calc.add.v1",
        "messaging.protocol"                   => "Polyn",
        "messaging.url"                        => nats.uri.to_s,
        "messaging.message_id"                 => msg.data.id,
        "messaging.message_payload_size_bytes" => JSON.generate(msg.data.to_h).bytesize,
      })
    end

    it "invalid message sends ACKTERM" do
      # Publishing with vanilla nats instead of polyn
      nats.publish("calc.add.v1", JSON.generate({ a: "1", b: "2" }))
      expect do
        subject.fetch
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end
end
