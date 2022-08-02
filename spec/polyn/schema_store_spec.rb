# frozen_string_literal: true

require "spec_helper"
require "nats/client"
require "polyn/schema_store"

RSpec.describe Polyn::SchemaStore do
  let(:store_name) { "STORE_NAME_TEST_STORE" }
  let(:nats) { NATS.connect }
  let(:js) { nats.jetstream }

  before(:each) do
    js.create_key_value(bucket: store_name)
  end

  describe "#save" do
    it "adds a schema to the store" do
      described_class.save(nats, "foo.bar.v1", { "foo" => "bar" }, name: store_name)
      entry = js.key_value(store_name).get("foo.bar.v1")
      expect(entry.value).to eq("{\"foo\":\"bar\"}")
    end
  end

  after(:each) do
    js.delete_key_value(store_name)
  end
end
