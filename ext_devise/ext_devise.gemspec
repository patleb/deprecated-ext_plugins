$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_devise"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_devise"
  s.summary     = "ExtDevise"
  s.description = "ExtDevise"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "devise", "~> 4.3"
  s.add_dependency "devise-bootstrap-views", "~> 0.0.11"
  s.add_dependency 'devise-i18n', "~> 1.4"
  s.add_dependency 'ext_rails', version
  # TODO s.add_dependency 'ext_async'
end
