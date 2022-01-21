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

RSpec.describe Polyn::Serializers::Json do
  let(:serializer) { Polyn::Serializers::Json.new }

  describe "#serialize" do
    it "serializes a Polyn::Event into JSON by calling #to_json on the event" do
      event = Polyn::Event.new(
        id:   "123",
        type: "test",
        data: {
          foo: "bar",
        },
      )

      expect(serializer.serialize(event)).to eq(event.to_h.to_json)
    end
  end

  describe "#deserialize" do
    it "deserializes a JSON string into a Polyn::Event" do
      event = serializer.deserialize({
        time:   time = Time.now.utc.iso8601,
        type:   "test.event",
        source: "/test/service",
        id:     id   = SecureRandom.uuid,
        data:   {
          foo: "bar",
        },
      }.to_json)

      expect(event).to be_an_instance_of(Polyn::Event)
      expect(event.id).to eq(id)
      expect(event.time).to eq(time)
      expect(event.type).to eq("test.event")
      expect(event.source).to eq("/test/service")
      expect(event.datacontenttype).to eq("application/json")
      expect(event.data).to eq({
        foo: "bar",
      })
    end
  end
end