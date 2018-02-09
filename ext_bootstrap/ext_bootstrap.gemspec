$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_bootstrap"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_bootstrap"
  s.summary     = "ExtBootstrap"
  s.description = "ExtBootstrap"
  s.license     = "MIT"

  s.files = Dir["{app,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "railties", "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
  s.add_dependency 'sassc-rails', '~> 1.3'
  s.add_dependency 'sass-rails'
  s.add_dependency 'autoprefixer-rails', '~> 7.1'
  s.add_dependency 'bootstrap-sass', '~> 3.3.7'
  s.add_dependency 'font-awesome-sass', '~> 4.7.0'
  s.add_dependency 'ext_sprockets'
end
