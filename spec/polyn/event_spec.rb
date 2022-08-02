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

RSpec.describe Polyn::Event do
  subject do
    Polyn::Event.new(
      type:   "test.event",
      source: "/test/service",
      data:   {
        foo: "bar",
      },
    )
  end

  describe "#specversion" do
    it "returns the default specversion" do
      expect(subject.specversion).to eq("1.0")
    end

    context "invalid version" do
      it "raises 'UnsupportedVersionError'" do
        expect do
          Polyn::Event.new(
            type:        "test.event",
            source:      "/test/service",
            specversion: "2.0",
            data:        {
              foo: "bar",
            },
          )
        end.to raise_error(Polyn::Event::UnsupportedVersionError)
      end
    end
  end

  describe "#id" do
    it "defaults to a uuid" do
      expect(subject.id).to_not be_nil
      expect(subject.id =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/).to be_truthy
    end

    it "returns the passed id" do
      expect(Polyn::Event.new(
        type:   "test.event",
        source: "/test/service",
        id:     "12345678-1234-1234-1234-1234567890ab",
        data:   {
          foo: "bar",
        },
      ).id).to eq("12345678-1234-1234-1234-1234567890ab")
    end
  end

  describe "#type" do
    it "returns the event type" do
      expect(subject.type).to eq("test.event")
    end
  end

  describe "#source" do
    it "returns the event source" do
      expect(subject.source).to eq("/test/service")
    end
  end

  describe "#full_source" do
    it "gives root if no source passed in " do
      expect(described_class.full_source).to eq("com:test:user:backend")
    end

    it "appends additional source information if provided" do
      expect(described_class.full_source("orders.new")).to eq("com:test:user:backend:orders:new")
    end
  end

  describe "#time" do
    it "defaults to the current time" do
      Timecop.freeze do
        expect(subject.time).to eq(Time.now.utc.iso8601)
      end
    end

    it "returns the passed time" do
      expect(Polyn::Event.new(
        type:   "test.event",
        source: "/test/service",
        time:   Time.new(2020, 1, 1, 12, 0, 0),
        data:   {
          foo: "bar",
        },
      ).time).to eq(Time.new(2020, 1, 1, 12, 0, 0))
    end
  end

  describe "#data" do
    it "returns the event data" do
      expect(subject.data).to eq({
        foo: "bar",
      })
    end
  end
end
