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

require "polyn/errors/validation_error"

RSpec.describe Polyn::Serializers::Json do
  describe "#serialize!" do
    it "serializes valid event" do
      event = Polyn::Event.new(
        type: "calc.mult.v1",
        data: {
          a: 1,
          b: 2,
        },
      )

      described_class.serialize!(:foo, event)
    end

    it "raises if event is not a Polyn::Event" do
      expect do
        described_class.serialize!(:foo, "foo")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if event is not a valid cloud event" do
      expect { described_class.serialize!(:foo, Polyn::Event.new(id: "", data: "foo", type: "calc.mult.v1")) }.to raise_error(Polyn::Errors::ValidationError)
    end
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

  describe "#deserialize" do
    context "valid event" do
      it "deserializes a JSON string into a Polyn::Event" do
        event = serializer.deserialize({
          time:            time = Time.now.utc.iso8601,
          type:            "calc.mult",
          source:          "com.test.service",
          id:              id   = SecureRandom.uuid,
          datacontenttype: "application/json",
          data:            {
            a: 1,
            b: 2,
          },
        }.to_json)

        expect(event).to be_an_instance_of(Polyn::Event)
        expect(event.id).to eq(id)
        expect(event.time).to eq(time)
        expect(event.type).to eq("calc.mult")
        expect(event.source).to eq("com.test.service")
        expect(event.datacontenttype).to eq("application/json")
        expect(event.data).to eq({
          a: 1,
          b: 2,
        })
      end
    end

    context "invalid event" do
      it "raises Polyn::Serializers::Errors::ValidationError" do
        expect do
          serializer.deserialize({
            time:   Time.now.utc.iso8601,
            type:   "calc.mult",
            source: "com.test.service",
            id:     SecureRandom.uuid,
            data:   {
            },
          }.to_json)
        end.to raise_error(Polyn::Serializers::Errors::ValidationError)
      end
    end
  end
end
