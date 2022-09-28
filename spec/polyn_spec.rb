# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:store_name) { "POLYN_TEST_STORE" }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:schema_store) do
    Polyn::SchemaStore.new(nats, name: store_name, schemas: {
      "calc.mult.v1" => JSON.generate({
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

  before(:each) do
    exporter.reset
  end

  subject do
    described_class.connect(nats, store_name: store_name, schema_store: schema_store)
  end

  describe "#publish" do
    before(:each) do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "my_consumer")
    end

    after(:each) do
      js.delete_stream("CALC")
    end

    it "publishes a message" do
      now = Time.now.iso8601
      subject.publish("calc.mult.v1", {
        a:         1,
        b:         2,
        timestamp: now,
      })

      msg = get_message("calc.mult.v1", "my_consumer", "CALC")

      event = JSON.parse(msg.data)
      expect(msg.subject).to eq("calc.mult.v1")
      expect(event["type"]).to eq("com.test.calc.mult.v1")
      expect(event["source"]).to eq("com:test:user:backend")
      expect(event["data"]["a"]).to eq(1)
      expect(event["data"]["b"]).to eq(2)
      expect(event["data"]["timestamp"]).to eq(now)

      # Tracing
      span = spans.first

      expect(spans.length).to eq(1)

      # https://www.w3.org/TR/trace-context/#traceparent-header
      expect(msg.header["traceparent"]).to eq("00-#{span.hex_trace_id}-#{span.hex_span_id}-01")

      expect(spans.length).to eq(1)
      expect(span.name).to eq("calc.mult.v1 send")
      expect(span.kind).to eq("PRODUCER")
      expect(span.attributes).to eq({
        "messaging.system"                     => "NATS",
        "messaging.destination"                => "calc.mult.v1",
        "messaging.protocol"                   => "Polyn",
        "messaging.url"                        => nats.uri.to_s,
        "messaging.message_id"                 => event["id"],
        "messaging.message_payload_size_bytes" => msg.data.bytesize,
      })
    end

    it "always includes a Nats-Msg-Id header" do
      subject.publish("calc.mult.v1", {
        a: 1,
        b: 2,
      }, reply_to: "foo")

      msg = get_message("calc.mult.v1", "my_consumer", "CALC")

      expect(msg.header["Nats-Msg-Id"]).to eq(JSON.parse(msg.data)["id"])
    end

    it "can include a custom header" do
      subject.publish("calc.mult.v1", {
        a: 1,
        b: 2,
      }, header: { "a header key" => "a header value" }, reply_to: "foo")

      msg = get_message("calc.mult.v1", "my_consumer", "CALC")

      expect(msg.header["a header key"]).to eq("a header value")
      expect(msg.header["Nats-Msg-Id"]).to eq(JSON.parse(msg.data)["id"])
      expect(msg.header["traceparent"]).to be_truthy
    end

    it "raises if msg doesn't conform to schema" do
      expect do
        subject.publish("calc.mult.v1", {
          a: "1",
          b: "2",
        })
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#pull_subscribe" do
    it "raises if type is invalid" do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "user_backend_calc_mult_v1")
      expect do
        subject.pull_subscribe("calc mult v1")
      end.to raise_error(Polyn::Errors::ValidationError)
      js.delete_stream("CALC")
    end

    it "raises if optional source invalid" do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "user_backend_foo_bar_calc_mult_v1")
      expect do
        subject.pull_subscribe("calc.mult.v1", source: "foo bar")
      end.to raise_error(Polyn::Errors::ValidationError)
      js.delete_stream("CALC")
    end

    it "raises if consumer was not created in NATS" do
      expect do
        subject.pull_subscribe("calc.mult.v1", source: "foo bar")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "gives PullSubscriber instance if successful" do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "user_backend_calc_mult_v1")
      expect(subject.pull_subscribe("calc.mult.v1")).to be_a(Polyn::PullSubscriber)
      js.delete_stream("CALC")
    end
  end

  describe "#subscribe" do
    it "turns msg data into an event" do
      mon  = Monitor.new
      done = mon.new_cond

      msgs = []
      subject.subscribe("calc.mult.v1") do |msg|
        msgs << msg
        mon.synchronize do
          done.signal
        end
      end

      subject.publish("calc.mult.v1", { a: 1, b: 2 })

      mon.synchronize { done.wait(1) }

      expect(msgs.count).to eq(1)
      expect(msgs[0].data).to be_a(Polyn::Event)
      expect(msgs[0].data.data[:a]).to eq(1)
      expect(msgs[0].data.data[:b]).to eq(2)

      # Tracing
      span = spans[1]

      expect(spans.length).to eq(2)
      expect(span.name).to eq("calc.mult.v1 receive")
      expect(span.kind).to eq("CONSUMER")
      expect(span.parent_span_id).to eq(spans[0].span_id)
      expect(span.attributes).to eq({
        "messaging.system"                     => "NATS",
        "messaging.destination"                => "calc.mult.v1",
        "messaging.protocol"                   => "Polyn",
        "messaging.url"                        => nats.uri.to_s,
        "messaging.message_id"                 => msgs[0].data.id,
        "messaging.message_payload_size_bytes" => JSON.generate(msgs[0].data.to_h).bytesize,
      })
    end
  end

  def get_message(type, consumer, stream)
    psub = js.pull_subscribe(type, consumer, stream: stream)

    msgs = psub.fetch(1)
    msgs.each(&:ack)
    msgs[0]
  end
end
