$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name          = "ext_pundit"
  s.version       = version
  s.authors       = ["Patrice Lebel"]
  s.email         = ["patleb@users.noreply.github.com"]
  s.homepage      = "https://github.com/patleb/ext_pundit"
  s.summary       = "OO authorization for Rails"
  s.description   = "Object oriented authorization for Rails applications"
  s.license       = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency "activesupport", "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"

  s.add_development_dependency "railties", "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
end
