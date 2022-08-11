# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:store_name) { "POLYN_TEST_STORE" }

  before(:each) do
    js.create_key_value(bucket: store_name)
  end

  after(:each) do
    js.delete_key_value(store_name)
  end

  describe "#publish" do
    before(:each) do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "my_consumer")

      add_schema("calc.mult.v1", {
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
      js.delete_stream("CALC")
    end

    it "publishes a message" do
      Polyn.publish(nats, "calc.mult.v1", {
        a: 1,
        b: 2,
      }, store_name: store_name)

      msg = get_message("calc.mult.v1", "my_consumer", "CALC")

      event = JSON.parse(msg.data)
      expect(msg.subject).to eq("calc.mult.v1")
      expect(event["type"]).to eq("com.test.calc.mult.v1")
      expect(event["source"]).to eq("com:test:user:backend")
      expect(event["data"]["a"]).to eq(1)
      expect(event["data"]["b"]).to eq(2)
    end

    it "adds triggered_by to polyntrace" do
      first_event = Polyn::Event.new({ type: "first.event", data: "foo" })

      Polyn.publish(nats, "calc.mult.v1", {
        a: 1,
        b: 2,
      }, store_name: store_name, triggered_by: first_event)

      msg = get_message("calc.mult.v1", "my_consumer", "CALC")

      event = JSON.parse(msg.data)
      expect(event["polyntrace"]).to eq([
                                          {
                                            "id"   => first_event.id,
                                            "type" => first_event.type,
                                            "time" => first_event.time,
                                          },
                                        ])
    end

    it "can include a header" do
      Polyn.publish(nats, "calc.mult.v1", {
        a: 1,
        b: 2,
      }, store_name: store_name, header: { "a header key" => "a header value" }, reply_to: "foo")

      msg = get_message("calc.mult.v1", "my_consumer", "CALC")

      expect(msg.header).to eq({ "a header key" => "a header value" })
    end

    it "raises if msg doesn't conform to schema" do
      expect do
        Polyn.publish(nats, "calc.mult.v1", {
          a: "1",
          b: "2",
        }, store_name: store_name)
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#pull_subscribe" do
    it "raises if type is invalid" do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "user_backend_calc_mult_v1")
      expect do
        Polyn.pull_subscribe(nats, "calc mult v1")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if optional source invalid" do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "user_backend_foo_bar_calc_mult_v1")
      expect do
        Polyn.pull_subscribe(nats, "calc.mult.v1", source: "foo bar")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if consumer was not created in NATS" do
      expect do
        Polyn.pull_subscribe(nats, "calc.mult.v1", source: "foo bar")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "gives PullSubscriber instance if successful" do
      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "user_backend_calc_mult_v1")
      expect(Polyn.pull_subscribe(nats, "calc.mult.v1")).to be_a(Polyn::PullSubscriber)
    end
  end

  describe "#subscribe" do
    it "turns msg data into an event" do
      mon  = Monitor.new
      done = mon.new_cond

      add_schema("calc.mult.v1", {
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

      msgs = []
      Polyn.subscribe(nats, "calc.mult.v1", store_name: store_name) do |msg|
        msgs << msg
        mon.synchronize do
          done.signal
        end
      end

      Polyn.publish(nats, "calc.mult.v1", { a: 1, b: 2 }, store_name: store_name)

      mon.synchronize { done.wait(1) }

      expect(msgs.count).to eq(1)
      expect(msgs[0].data).to be_a(Polyn::Event)
      expect(msgs[0].data.data[:a]).to eq(1)
      expect(msgs[0].data.data[:b]).to eq(2)
    end
  end

  def add_schema(type, schema)
    Polyn::SchemaStore.save(nats, type, schema, name: store_name)
  end

  def get_message(type, consumer, stream)
    psub = js.pull_subscribe(type, consumer, stream: stream)

    msgs = psub.fetch(1)
    msgs.each(&:ack)
    msgs[0]
  end
end
