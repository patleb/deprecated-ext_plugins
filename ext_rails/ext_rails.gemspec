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

  # https://github.com/maximeg/activecleaner
  # gem 'active_record-mti'
  # https://github.com/k0kubun/activerecord-precounter
  # https://github.com/oelmekki/activerecord_any_of
  # https://github.com/brianhempel/active_record_union
  s.add_dependency 'active_record_query_trace'
  s.add_dependency 'active_record_upsert'
  s.add_dependency 'active_type', '~> 0.7'
  s.add_dependency 'activerecord-rescue_from_duplicate'
  s.add_dependency 'activevalidators'
  s.add_dependency 'acts_as_list'
  # https://github.com/Faveod/arel-extensions
  # https://github.com/dylanahsmith/ar_transaction_changes
  s.add_dependency 'baby_squeel', '~> 1.2'
  s.add_dependency 'bootsnap'
  s.add_dependency 'bumbler', '~> 0.3'
  # gem 'closure_tree'
  # https://github.com/willbryant/columns_on_demand
  s.add_dependency 'countries', '~> 2.1'
  s.add_dependency 'email_prefixer', '~> 1.2'
  s.add_dependency 'ext_mail', version
  s.add_dependency 'ext_ruby'
  # s.add_dependency 'faster_path', '~> 0.1.13'
  # https://www.rust-lang.org/en-US/other-installers.html
  s.add_dependency 'hamlit-rails', '~> 0.2'
  s.add_dependency 'hashid-rails'
  s.add_dependency 'http_accept_language', '~> 2.1'
  # https://github.com/pat/gutentag
  s.add_dependency 'i18n-debug', '~> 1.1'
  s.add_dependency 'jsonb_accessor', '~> 1.0'
  s.add_dependency 'logidze', '~> 0.5'
  s.add_dependency 'mail_interceptor'
  s.add_dependency 'money-rails', '~> 1.9'
  s.add_dependency 'monogamy', '>= 0.0.2'
  # mv-postgresql
  s.add_dependency 'nestive', '~> 0.6'
  s.add_dependency 'null-logger', '~> 0.1'
  s.add_dependency 'oj', '~> 2.18'
  s.add_dependency 'oj_mimic_json', '~> 1.0'
  # gem 'pluck_to_hash'
  s.add_dependency 'polymorphic_constraints'
  s.add_dependency 'pg', '~> 0.21'
  s.add_dependency 'query_diet', '~> 0.6'
  s.add_dependency 'rack_lineprof', '~> 0.1'
  s.add_dependency 'rails', "~> #{ExtPlugins::VERSION::RAILS_MAJOR}.#{ExtPlugins::VERSION::RAILS_MINOR}"
  s.add_dependency 'rails-i18n', '~> 5.0'
  s.add_dependency 'rails_select_on_includes'
  # https://github.com/nullobject/rein
  s.add_dependency 'route_translator'
  # https://github.com/wvanbergen/scoped_search
  s.add_dependency 'settings_yml'
  s.add_dependency 'store_base_sti_class'
  s.add_dependency 'time_difference', '~> 0.7'
  # s.add_dependency 'ulid'
  # https://github.com/markets/unscoped_associations
  # gem "zero_downtime_migrations"
  # https://github.com/rbspy/rbspy
end
