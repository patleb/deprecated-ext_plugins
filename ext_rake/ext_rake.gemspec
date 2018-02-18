$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ext_rake/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rake"
  s.version     = ExtRake::VERSION
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rake"
  s.summary     = "ExtRake"
  s.description = "ExtRake"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "colorize", "~> 0.8"
  s.add_dependency "dotiw", "~> 3.1"
  s.add_dependency "require_all", "~> 1.4"
  s.add_dependency "pgslice"
  s.add_dependency "ext_aws_sdk"
  s.add_dependency "ext_mail"
  s.add_dependency "settings_yml"

  s.add_development_dependency "rake"
  s.add_development_dependency "railties"
end
