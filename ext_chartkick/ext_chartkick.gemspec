$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_chartkick"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_chartkick"
  s.summary     = "ExtChartkick"
  s.description = "ExtChartkick"
  s.license     = "MIT"

  s.files = Dir["{app,lib}/**/*", "LICENSE.txt", "README.md"]

  s.add_dependency "railties", "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
end
