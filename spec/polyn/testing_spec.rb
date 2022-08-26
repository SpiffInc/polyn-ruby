# frozen_string_literal: true

require "spec_helper"
require "polyn/testing"

Polyn::Testing.setup

RSpec.describe Polyn::Testing do
  describe "#setup" do
    include_context :polyn
    it "makes a unique stream for the test" do
      name = stream_name_from_description("Polyn::Testing#setup makes a unique stream for the test")
      info = js.stream_info(name)
      expect(info.config.name).to eq(name)
    end

    it "deletes the stream when its done" do
      name = stream_name_from_description("Polyn::Testing#setup makes a unique stream for the test")
      expect {js.stream_info(name)}.to raise_error(NATS::JetStream::Error::StreamNotFound)
    end
  end
end
