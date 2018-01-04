$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_async"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_async"
  s.summary     = "ExtAsync"
  s.description = "ExtAsync"
  s.license     = "MIT"

  s.files = Dir["{app,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "ext_rails", version
  s.add_dependency "ext_rake"
  s.add_dependency "ext_shell", version
end
