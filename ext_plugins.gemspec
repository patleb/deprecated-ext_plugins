# Maintain your gem's version:
require_relative "./version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_plugins"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_plugins"
  s.summary     = "ExtPlugins"
  s.description = "ExtPlugins"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path(".ruby-version", __dir__)).strip}"

  s.add_dependency "rails", "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
  s.add_dependency "ext_async",       version
  s.add_dependency "ext_aws_sdk",     version
  s.add_dependency "ext_bootstrap",   version
  s.add_dependency "ext_capistrano",  version
  s.add_dependency "ext_chartkick",   version
  s.add_dependency "ext_coffee",      version
  s.add_dependency "ext_devise",      version
  s.add_dependency "ext_globals",     version
  s.add_dependency "ext_mail",        version
  s.add_dependency "ext_pundit",      version
  s.add_dependency "ext_rails",       version
  s.add_dependency "ext_rails_admin", version
  s.add_dependency "ext_rake"
  s.add_dependency "ext_ruby"
  s.add_dependency "ext_settings",    version
  s.add_dependency "ext_shell",       version
  s.add_dependency "ext_tasks",       version
  s.add_dependency "ext_throttler",   version
  s.add_dependency "ext_whenever",    version
  s.add_dependency "settings_yml"
  s.add_dependency "sun_cap"
end
