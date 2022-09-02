# frozen_string_literal: true

require "spec_helper"
require "polyn/testing"

nats = NATS.connect
js   = nats.jetstream
js.create_key_value(bucket: Polyn::SchemaStore::STORE_NAME)
Polyn::Testing.setup

RSpec.describe Polyn::Testing do
  describe "#setup" do
    include_context :polyn

    it "puts a shareable schema store in the running thread" do
      expect(Thread.current[:polyn_schema_store]).to be_instance_of(Polyn::SchemaStore)
    end
  end
end
