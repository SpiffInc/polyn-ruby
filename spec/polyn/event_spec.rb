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
      source: "test.service",
      data:   {
        foo: "bar",
      },
    )
  end

  describe "#specversion" do
    it "returns the default specversion" do
      expect(subject.specversion).to eq(Polyn::Event::CLOUD_EVENT_VERSION)
    end

    it "accepts non-breaking versions" do
      event = Polyn::Event.new(
        type:        "test.event",
        source:      "test.service",
        specversion: "1.1.0",
        data:        {
          foo: "bar",
        },
      )
      expect(event.specversion).to eq("1.1.0")
    end

    context "invalid version" do
      it "raises 'UnsupportedVersionError'" do
        expect do
          Polyn::Event.new(
            type:        "test.event",
            source:      "test.service",
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
        source: "test.service",
        id:     "12345678-1234-1234-1234-1234567890ab",
        data:   {
          foo: "bar",
        },
      ).id).to eq("12345678-1234-1234-1234-1234567890ab")
    end
  end

  describe "#type" do
    it "returns the event type" do
      expect(subject.type).to eq("com.test.test.event")
    end
  end

  describe "#full_type" do
    it "full_type/1 prefixes domain" do
      expect("com.test.user.created.v1").to eq(described_class.full_type("user.created.v1"))
    end

    it "full_type/1 ignores existing domain prefix" do
      expect("com.test.user.created.v1").to eq(described_class.full_type("com.test.user.created.v1"))
    end

    it "full_type/1 raises if type is invalid" do
      expect do
        described_class.full_type("com test user created v1")
      end.to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#source" do
    it "returns the event source" do
      expect(subject.source).to eq("com:test:user:backend:test:service")
    end

    it "can init with nil source" do
      expect(Polyn::Event.new(
        type: "test.event",
        data: {
          foo: "bar",
        },
      ).source).to eq("com:test:user:backend")
    end

    it "does not duplicate source root" do
      expect(Polyn::Event.new(
        type:   "test.event",
        source: "com:test:user:backend",
        data:   {
          foo: "bar",
        },
      ).source).to eq("com:test:user:backend")
    end

    it "does not duplicate source root with custom" do
      expect(Polyn::Event.new(
        type:   "test.event",
        source: "com:test:user:backend:test:service",
        data:   {
          foo: "bar",
        },
      ).source).to eq("com:test:user:backend:test:service")
    end
  end

  describe "#full_source" do
    it "gives root if no source passed in " do
      expect(described_class.full_source).to eq("com:test:user:backend")
    end

    it "appends additional source information if provided" do
      expect(described_class.full_source("orders.new")).to eq("com:test:user:backend:orders:new")
    end

    it "raises if source name is invalid" do
      expect do
        described_class.full_source("orders   new")
      end.to raise_error(Polyn::Errors::ValidationError)
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
        source: "test.service",
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

  describe "#datacontenttype" do
    it "defaults to applicationjson" do
      expect(subject.datacontenttype).to eq("application/json")
    end
  end

  describe "#polyndata" do
    it "has client information" do
      expect(subject.polyndata[:clientlang]).to eq("ruby")
      expect(subject.polyndata[:clientlangversion]).to eq(RUBY_VERSION)
      expect(subject.polyndata[:clientversion]).to eq(Polyn::VERSION)
    end
  end
end
