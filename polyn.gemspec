# frozen_string_literal: true

require_relative "lib/polyn/version"

Gem::Specification.new do |spec|
  spec.name          = "polyn"
  spec.version       = Polyn::VERSION
  spec.authors       = ["Jarod"]
  spec.email         = ["therealfugu@gmail.com"]

  spec.summary       = "Polyn Service Framework"
  spec.description   = "A microservice built on top of Apache Kafka"
  spec.homepage      = "https://github.com/polyn-services/polyn-rb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby-edge", "~> 0.6.0"
  spec.add_dependency "semantic_logger",      "~> 4.8"
end
