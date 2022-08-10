# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Naming do
  describe "#dot_to_colon" do
    it "replaces dots" do
      expect(described_class.dot_to_colon("com.acme.user.created.v1.schema.v1")).to eq("com:acme:user:created:v1:schema:v1")
    end
  end

  describe "#dot_to_underscore" do
    it "turns dot to underscore" do
      expect(described_class.dot_to_underscore("foo.bar.baz")).to eq("foo_bar_baz")
    end
  end

  describe "#colon_to_underscore" do
    it "turns colon to underscore" do
      expect(described_class.colon_to_underscore("foo:bar:baz")).to eq("foo_bar_baz")
    end
  end

  describe "#validate_domain_name!!" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_domain_name!("com.test") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_domain_name!("com.test.foo") }.to_not raise_error
    end

    it "valid name that's alphanumeric and colon separated passes" do
      expect { described_class.validate_domain_name!("com:test") }.to_not raise_error
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_domain_name!("user   created")
      end.to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have tabs" do
      expect { described_class.validate_domain_name!("user\tcreated") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_domain_name!("user\n\rcreated") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have special characters" do
      expect { described_class.validate_domain_name!("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_domain_name!(".user") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_domain_name!("user.") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_domain_name!(":user") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_domain_name!("user:") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't be nil" do
      expect { described_class.validate_domain_name!(nil) }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end
  end

  describe "#validate_source_root!" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_source_root!("com.test") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_source_root!("com.test.foo") }.to_not raise_error
    end

    it "valid name that's alphanumeric and colon separated passes" do
      expect { described_class.validate_source_root!("com:test") }.to_not raise_error
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_source_root!("user   created")
      end.to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have tabs" do
      expect { described_class.validate_source_root!("user\tcreated") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_source_root!("user\n\rcreated") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't have special characters" do
      expect { described_class.validate_source_root!("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_source_root!(".user") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_source_root!("user.") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_source_root!(":user") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_source_root!("user:") }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end

    it "name can't be nil" do
      expect { described_class.validate_source_root!(nil) }
        .to raise_error(Polyn::Errors::ConfigurationError)
    end
  end

  describe "#validate_source_name!" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_source_name!("com.test") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_source_name!("com.test.foo") }.to_not raise_error
    end

    it "valid name that's alphanumeric and colon separated passes" do
      expect { described_class.validate_source_name!("com:test") }.to_not raise_error
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_source_name!("user   created")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have tabs" do
      expect { described_class.validate_source_name!("user\tcreated") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_source_name!("user\n\rcreated") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have special characters" do
      expect { described_class.validate_source_name!("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_source_name!(".user") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_source_name!("user.") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_source_name!(":user") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_source_name!("user:") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't be nil" do
      expect { described_class.validate_source_name!(nil) }
        .to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#validate_event_type!" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_event_type!("user.created") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_event_type!("user.created.foo") }.to_not raise_error
    end

    it "name can't have colons" do
      expect do
        described_class.validate_event_type!("user:test")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_event_type!("user   created")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have tabs" do
      expect { described_class.validate_event_type!("user\tcreated") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_event_type!("user\n\rcreated") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't have special characters" do
      expect { described_class.validate_event_type!("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_event_type!(".user") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_event_type!("user.") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_event_type!(":user") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_event_type!("user:") }
        .to raise_error(Polyn::Errors::ValidationError)
    end

    it "name can't be nil" do
      expect { described_class.validate_event_type!(nil) }
        .to raise_error(Polyn::Errors::ValidationError)
    end
  end

  describe "#trim_domain_prefix" do
    it "removes prefix when dots" do
      expect("user.created.v1.schema.v1").to eq(
               described_class.trim_domain_prefix("com.test.user.created.v1.schema.v1"),
             )
    end

    it "removes prefix when colon" do
      expect("user:created:v1:schema:v1").to eq(
             described_class.trim_domain_prefix("com:test:user:created:v1:schema:v1"),
           )
    end

    it "only removes first occurence" do
      expect("user.created.com.test.v1.schema.v1").to eq(
             described_class.trim_domain_prefix("com.test.user.created.com.test.v1.schema.v1"),
           )
    end
  end

  describe "#consumer_name" do
    it "raises if event type is invalid" do
      expect do
        described_class.consumer_name("foo bar")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "raises if optional source is invalid" do
      expect do
        described_class.consumer_name("foo.bar", "my source")
      end.to raise_error(Polyn::Errors::ValidationError)
    end

    it "uses source_root by default" do
      expect(described_class.consumer_name("foo.bar.v1")).to eq("user_backend_foo_bar_v1")
    end

    it "takes optional source" do
      expect(described_class.consumer_name("foo.bar.v1",
        "my.source")).to eq("user_backend_my_source_foo_bar_v1")
    end

    it "takes colon separated source" do
      expect(described_class.consumer_name("foo.bar.v1",
        "my:source")).to eq("user_backend_my_source_foo_bar_v1")
    end

    it "takes domain prefixed type" do
      expect(described_class.consumer_name("com.test.foo.bar.v1",
        "my:source")).to eq("user_backend_my_source_foo_bar_v1")
    end
  end
end
