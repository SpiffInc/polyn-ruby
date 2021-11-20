require "spec_helper"

RSpec.describe Polyn::Utils::String do
  describe "#to_camel_case" do
    it "converts the string to camelcase" do
      expect(described_class.to_camel_case("test_string")).to eq("testString")
    end
  end

  describe "#to_snake_case" do
    it "converts the string to snake case" do
      expect(described_class.to_snake_case("testString")).to eq("test_string")
    end
  end
end