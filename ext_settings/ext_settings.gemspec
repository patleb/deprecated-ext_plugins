$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_settings"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_settings"
  s.summary     = "ExtSettings"
  s.description = "ExtSettings"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency "ext_rails", version

  s.add_development_dependency 'set_things_engine_test', '0.1.2'
end
