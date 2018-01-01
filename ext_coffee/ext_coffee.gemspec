$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_coffee"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_coffee"
  s.summary     = "ExtCoffee"
  s.description = "ExtCoffee"
  s.license     = "MIT"

  s.files = `git ls-files -z`.split("\x0")

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency "railties", "~> 5.0"
  s.add_dependency 'ext_ruby', '>= 0.7'
  s.add_dependency 'coffee-rails', '~> 4.2'
  s.add_dependency 'uglifier', '>= 1.3.0'
  s.add_dependency 'alaska', '>= 1.2.2'
  # TODO https://github.com/sfcgeorge/capybara-jsdom
end
