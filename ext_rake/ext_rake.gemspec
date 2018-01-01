$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rake"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rake"
  s.summary     = "ExtRake"
  s.description = "ExtRake"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency "colorize", "~> 0.8"
  s.add_dependency "dotiw", "~> 3.1"
  s.add_dependency "require_all", "~> 1.4"
  s.add_dependency "ext_aws_sdk", version
  s.add_dependency "ext_mail", version
  s.add_dependency "settings_yml"

  s.add_development_dependency "rake"
  s.add_development_dependency "railties"
end
