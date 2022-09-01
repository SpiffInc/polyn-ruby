# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Serializers::Json do
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }
  let(:store_name) { "JSON_SERIALIZER_TEST_STORE" }
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

  subject do
    described_class.new(schema_store)
  end

  describe "#serialize!" do
    it "serializes valid event" do
      event = Polyn::Event.new(
        type: "calc.mult.v1",
        data: {
          a: 1,
          b: 2,
        },
      )

      json  = subject.serialize!(event)
      event = JSON.parse(json)
      expect(event["data"]["a"]).to eq(1)
      expect(event["data"]["b"]).to eq(2)
      expect(event["type"]).to eq("com.test.calc.mult.v1")
    end

    it "raises if event is not a Polyn::Event" do
      expect do
        subject.serialize!("foo")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if event is not a valid cloud event" do
      expect do
        subject.serialize!(
          Polyn::Event.new(id: "", data: "foo", type: "calc.mult.v1"),
        )
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if event data is not valid" do
      expect do
        subject.serialize!(
          Polyn::Event.new(data: "foo", type: "calc.mult.v1"),
        )
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#deserialize!" do
    it "deserializes valid event" do
      json = JSON.generate({
        id:          "foo",
        specversion: "1.0",
        type:        "com.test.calc.mult.v1",
        source:      "calculation.engine",
        data:        {
          a: 1,
          b: 2,
        },
      })

      event = subject.deserialize!(json)

      expect(event.data[:a]).to eq(1)
      expect(event.data[:b]).to eq(2)
      expect(event.type).to eq("com.test.calc.mult.v1")
    end

    it "raises if json not parseable" do
      expect do
        subject.deserialize!("foo")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "it raises if no schema exists" do
      json = JSON.generate({
        id:          "foo",
        specversion: "1.0",
        type:        "com.test.foo.bar",
        source:      "calculation.engine",
        data:        {
          a: 1,
          b: 2,
        },
      })

      expect do
        subject.deserialize!(json)
      end.to raise_error(Polyn::Errors::SchemaError)
    end

    it "it raises if doesn't match schema" do
      json = JSON.generate({
        id:          "foo",
        specversion: "1.0",
        type:        "com.test.calc.mult.v1",
        source:      "calculation.engine",
        data:        {
          a: nil,
          b: "2",
        },
      })

      expect do
        subject.deserialize!(json)
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if event is not a valid cloud event" do
      expect do
        subject.deserialize!(
          JSON.generate({ id: "", data: "foo", type: "calc.mult.v1" }),
        )
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#deserialize" do
    it "deserializes valid event" do
      json = JSON.generate({
        id:          "foo",
        specversion: "1.0",
        type:        "com.test.calc.mult.v1",
        source:      "calculation.engine",
        data:        {
          a: 1,
          b: 2,
        },
      })

      event = subject.deserialize(json)

      expect(event.data[:a]).to eq(1)
      expect(event.data[:b]).to eq(2)
      expect(event.type).to eq("com.test.calc.mult.v1")
    end

    it "gives error message if invalid" do
      errors = subject.deserialize(
        JSON.generate({ id: "", data: "foo", type: "calc.mult.v1" }),
      )
      expect(errors).to be_a(Polyn::Errors::ValidationError)
    end
  end

  def add_schema(type, schema)
    schema_store.save(type, schema)
  end
end
