# frozen_string_literal: true

# Copyright 2021-2022 Spiff, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "polyn/schema_store"
require "polyn/errors/validation_error"
require "nats/client"

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

  # describe "#serialize" do
  #   context "valid event" do
  #     it "serializes a Polyn::Event into JSON by calling #to_json on the event" do
  #       event = Polyn::Event.new(
  #         id:     SecureRandom.uuid,
  #         source: "com.test.service",
  #         type:   "calc.mult",
  #         data:   {
  #           a: 1,
  #           b: 2,
  #         },
  #       )

  #       puts event.to_h

  #       expect(serializer.serialize(event)).to eq(event.to_h.to_json)
  #     end
  #   end

  #   context "invalid event" do
  #     it "raises Polyn::Serializers::Errors::ValidationError" do
  #       event = Polyn::Event.new(
  #         id:     SecureRandom.uuid,
  #         source: "com.test.service",
  #         type:   "calc.mult",
  #         data:   {},
  #       )

  #       expect do
  #         serializer.serialize(event)
  #       end.to raise_error(Polyn::Serializers::Errors::ValidationError)
  #     end
  #   end
  # end

  # describe "#deserialize" do
  #   context "valid event" do
  #     it "deserializes a JSON string into a Polyn::Event" do
  #       event = serializer.deserialize({
  #         time:            time = Time.now.utc.iso8601,
  #         type:            "calc.mult",
  #         source:          "com.test.service",
  #         id:              id   = SecureRandom.uuid,
  #         datacontenttype: "application/json",
  #         data:            {
  #           a: 1,
  #           b: 2,
  #         },
  #       }.to_json)

  #       expect(event).to be_an_instance_of(Polyn::Event)
  #       expect(event.id).to eq(id)
  #       expect(event.time).to eq(time)
  #       expect(event.type).to eq("calc.mult")
  #       expect(event.source).to eq("com.test.service")
  #       expect(event.datacontenttype).to eq("application/json")
  #       expect(event.data).to eq({
  #         a: 1,
  #         b: 2,
  #       })
  #     end
  #   end

  #   context "invalid event" do
  #     it "raises Polyn::Serializers::Errors::ValidationError" do
  #       expect do
  #         serializer.deserialize({
  #           time:   Time.now.utc.iso8601,
  #           type:   "calc.mult",
  #           source: "com.test.service",
  #           id:     SecureRandom.uuid,
  #           data:   {
  #           },
  #         }.to_json)
  #       end.to raise_error(Polyn::Serializers::Errors::ValidationError)
  #     end
  #   end
  # end
end
