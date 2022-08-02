# frozen_string_literal: true

require "spec_helper"
require "polyn/naming"
require "polyn/errors/configuration_error"

RSpec.describe Polyn::Naming do
  describe "#validate_domain_name" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_domain_name("com.test") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_domain_name("com.test.foo") }.to_not raise_error
    end

    it "valid name that's alphanumeric and colon separated passes" do
      expect { described_class.validate_domain_name("com:test") }.to_not raise_error
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_domain_name("user   created")
      end.to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have tabs" do
      expect { described_class.validate_domain_name("user\tcreated") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_domain_name("user\n\rcreated") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have special characters" do
      expect { described_class.validate_domain_name("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_domain_name(".user") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_domain_name("user.") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_domain_name(":user") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_domain_name("user:") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't be nil" do
      expect { described_class.validate_domain_name(nil) }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end
  end
end
