# Maintain your gem's version:
require_relative "./version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_plugins"
  s.version     = ExtPlugins::VERSION::STRING
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_plugins"
  s.summary     = "ExtPlugins"
  s.description = "ExtPlugins"
  s.license     = "MIT"

  s.files = Dir["MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path(".ruby-version", __dir__)).strip}"

  s.add_dependency "rails", "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
end
