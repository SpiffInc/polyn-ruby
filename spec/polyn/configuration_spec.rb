# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Configuration do
  subject do
    described_class.new
  end

  describe "configuration" do
    it "raises if no domain" do
      expect { subject.domain }.to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "raises if domain is not a valid format" do
      expect do
        subject.domain = "com test"
      end.to raise_error(Polyn::Errors::ConfigurationError)
    end
  end

  it "raises if no source_root" do
    expect { subject.source_root }.to raise_error(Polyn::Errors::ConfigurationError)
  end

  it "raises if source_root is not a valid format" do
    expect do
      subject.source_root = "com test"
    end.to raise_error(Polyn::Errors::ConfigurationError)
  end
end
