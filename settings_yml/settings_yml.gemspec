$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "settings_yml/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "settings_yml"
  s.version     = SettingsYml::VERSION
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/settings_yml"
  s.summary     = "SettingsYml"
  s.description = "SettingsYml"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency 'activesupport', '~> 5.0'
  s.add_dependency "chronic_duration", "~> 0.10.6"
  s.add_dependency 'ext_ruby'
end
