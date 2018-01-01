$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rails"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rails"
  s.summary     = "ExtRails"
  s.description = "ExtRails"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'active_record_query_trace'
  s.add_dependency 'active_type', '~> 0.7'
  s.add_dependency 'activerecord-rescue_from_duplicate'
  s.add_dependency 'activevalidators'
  s.add_dependency 'baby_squeel', '~> 1.2'
  s.add_dependency 'bumbler', '~> 0.3'
  s.add_dependency 'countries', '~> 2.1'
  s.add_dependency 'email_prefixer', '~> 1.2'
  s.add_dependency 'ext_mail', version
  s.add_dependency 'ext_ruby'
  s.add_dependency 'hamlit-rails', '~> 0.2'
  s.add_dependency 'http_accept_language', '~> 2.1'
  s.add_dependency 'i18n-debug', '~> 1.1'
  s.add_dependency 'jsonb_accessor', '~> 1.0'
  s.add_dependency 'logidze', '~> 0.5'
  s.add_dependency 'mail_interceptor'
  s.add_dependency 'money-rails', '~> 1.9'
  s.add_dependency 'monogamy', '>= 0.0.2'
  s.add_dependency 'nestive', '~> 0.6'
  s.add_dependency 'null-logger', '~> 0.1'
  s.add_dependency 'oj', '~> 2.18'
  s.add_dependency 'oj_mimic_json', '~> 1.0'
  s.add_dependency 'pg', '~> 0.21'
  s.add_dependency 'query_diet', '~> 0.6'
  s.add_dependency 'rack_lineprof', '~> 0.1'
  s.add_dependency 'rails', "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
  s.add_dependency 'rails-i18n', '~> 5.0'
  s.add_dependency 'settings_yml'
  s.add_dependency 'time_difference', '~> 0.7'
end
