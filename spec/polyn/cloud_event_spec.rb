# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::CloudEvent do
  describe "#to_h" do
    it "returns the cloud event schema as a hash" do
      expect(described_class.to_h).to be_a(Hash)
    end
  end
end
