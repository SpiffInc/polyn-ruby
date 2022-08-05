# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Serializers::Json do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:store_name) { "JSON_SERIALIZER_TEST_STORE" }

  before(:each) do
    js.create_key_value(bucket: store_name)
  end

  after(:each) do
    js.delete_key_value(store_name)
  end

  describe "#serialize!" do
    it "serializes valid event" do
      add_schema("calc.mult.v1", {
        "data" => {
          "type"       => "object",
          "properties" => {
            "a" => { "type" => "integer" },
            "b" => { "type" => "integer" },
          },
        },
      })

      event = Polyn::Event.new(
        type: "calc.mult.v1",
        data: {
          a: 1,
          b: 2,
        },
      )

      json  = described_class.serialize!(nats, event, store_name: store_name)
      event = JSON.parse(json)
      expect(event["data"]["a"]).to eq(1)
      expect(event["data"]["b"]).to eq(2)
      expect(event["type"]).to eq("com.test.calc.mult.v1")
    end

    it "raises if event is not a Polyn::Event" do
      expect do
        described_class.serialize!(nats, "foo", store_name: store_name)
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if event is not a valid cloud event" do
      expect do
        described_class.serialize!(nats,
          Polyn::Event.new(id: "", data: "foo", type: "calc.mult.v1"), store_name: store_name)
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if event data is not valid" do
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
        described_class.serialize!(nats,
          Polyn::Event.new(data: "foo", type: "calc.mult.v1"), store_name: store_name)
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  def add_schema(type, schema)
    Polyn::SchemaStore.save(nats, type, schema, name: store_name)
  end
end
