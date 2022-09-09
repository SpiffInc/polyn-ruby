# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::SchemaStore do
  let(:store_name) { "SCHEMA_STORE_TEST_STORE" }
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }

  subject do
    described_class.new(nats, name: store_name, schemas: {})
  end

  before(:each) do
    js.create_key_value(bucket: store_name)
  end

  after(:each) do
    js.delete_key_value(store_name)
  end

  describe "#new" do
    it "error if store does not exist" do
      expect do
        described_class.new(nats, name: "BAD_STORE")
      end.to raise_error(Polyn::Errors::SchemaError)
    end

    it "loads all schemas" do
      js.key_value(store_name).put("foo.bar.v1", "{\"foo\":\"bar\"}")
      js.key_value(store_name).put("bar.baz.v1", "{\"bar\":\"baz\"}")
      store = described_class.new(nats, name: store_name)
      expect(store.schemas).to eq({
        "foo.bar.v1" => "{\"foo\":\"bar\"}",
        "bar.baz.v1" => "{\"bar\":\"baz\"}",
      })
    end
  end

  describe "#save" do
    it "adds a schema to the store" do
      subject.save("new.one.v1", { "foo" => "bar" })
      expect(subject.get!("new.one.v1")).to eq("{\"foo\":\"bar\"}")
    end
  end

  describe "#get!" do
    it "gets a schema from the store" do
      subject.save("foo.bar.v1", { "foo" => "bar" })
      expect(subject.get!("foo.bar.v1")).to eq("{\"foo\":\"bar\"}")
    end

    it "error if schema does not exist" do
      expect do
        subject.get!("not.a.thing.v1")
      end.to raise_error(Polyn::Errors::SchemaError)
    end
  end

  describe "#get" do
    it "gets a schema from the store" do
      subject.save("foo.bar.v1", { "foo" => "bar" })
      expect(subject.get("foo.bar.v1")).to eq("{\"foo\":\"bar\"}")
    end

    it "error if schema does not exist" do
      error = subject.get("not.a.thing.v1")
      expect(error).to be_a(Polyn::Errors::SchemaError)
    end
  end

  describe "#schemas" do
    it "gets cached schemas" do
      subject.save("foo.bar.v1", { "foo" => "bar" })
      subject.save("bar.qux.v1", { "bar" => "qux" })
      schemas = subject.schemas
      expect(schemas).to eq({
        "foo.bar.v1" => "{\"foo\":\"bar\"}",
        "bar.qux.v1" => "{\"bar\":\"qux\"}",
      })
    end

    it "no messages is empty hash" do
      empty_bucket = "SCHEMA_STORE_TEST_STORE_EMPTY"
      js.create_key_value(bucket: empty_bucket)
      schemas      = described_class.new(nats, name: empty_bucket).schemas
      expect(schemas).to eq({})
      js.delete_key_value(empty_bucket)
    end

    it "deleted schemas do not appear" do
      bucket  = nats.jetstream.key_value(store_name)
      bucket.put("foo.bar.v1", "{\"foo\":\"bar\"}")
      bucket.delete("foo.bar.v1")
      schemas = subject.schemas
      expect(schemas).to eq({})
    end
  end
end
