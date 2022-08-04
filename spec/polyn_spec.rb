# frozen_string_literal: true

require "spec_helper"
require "polyn/errors/validation_error"
require "polyn/schema_store"

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
    it "publishes a message" do
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

      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "my_consumer")

      Polyn.publish(nats, "calc.mult.v1", {
        a: 1,
        b: 2,
      }, store_name: store_name)

      psub = js.pull_subscribe("calc.mult.v1", "my_consumer", stream: "CALC")

      msgs = psub.fetch(1)
      msgs.each do |msg|
        event = JSON.parse(msg.data)
        expect(msg.subject).to eq("calc.mult.v1")
        expect(event["type"]).to eq("com.test.calc.mult.v1")
        expect(event["source"]).to eq("com:test:user:backend")
        expect(event["data"]["a"]).to eq(1)
        expect(event["data"]["b"]).to eq(2)
        msg.ack
      end

      js.delete_stream("CALC")
    end

    it "adds triggered_by to polyntrace" do
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

      js.add_stream(name: "CALC", subjects: ["calc.mult.v1"])
      js.add_consumer("CALC", durable_name: "my_consumer")

      first_event = Polyn::Event.new({ type: "first.event", data: "foo" })

      Polyn.publish(nats, "calc.mult.v1", {
        a: 1,
        b: 2,
      }, store_name: store_name, triggered_by: first_event)

      psub = js.pull_subscribe("calc.mult.v1", "my_consumer", stream: "CALC")

      msgs = psub.fetch(1)
      msgs.each do |msg|
        event = JSON.parse(msg.data)
        expect(event["polyntrace"]).to eq([
                                            {
                                              "id"   => first_event.id,
                                              "type" => first_event.type,
                                              "time" => first_event.time,
                                            },
                                          ])
        msg.ack
      end

      js.delete_stream("CALC")
    end

    it "raises if msg doesn't conform to schema" do
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

      expect do
        Polyn.publish(nats, "calc.mult.v1", {
          a: "1",
          b: "2",
        }, store_name: store_name)
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  def add_schema(type, schema)
    Polyn::SchemaStore.save(nats, type, schema, name: store_name)
  end
end
