# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn do
  describe "configuration" do
    it "takes config block" do
      Polyn.configure do |config|
        config.domain      = "com.test"
        config.source_root = "users"
      end

      config = Polyn.configuration

      expect(config.domain).to eq("com.test")
      expect(config.source_root).to eq("users")
    end
  end
end
