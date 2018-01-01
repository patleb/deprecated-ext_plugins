$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'ext_rails_admin'
  s.version = version
  s.authors = ['Patrice Lebel']
  s.email = ['patleb@users.noreply.github.com']
  s.homepage = 'https://github.com/patleb/ext_rails_admin'
  s.summary = 'Admin for Rails'
  s.description = 'RailsAdmin is a Rails engine that provides an easy-to-use interface for managing your data.'
  s.licenses = 'MIT'

  s.files = Dir['Gemfile', 'LICENSE.md', 'README.md', 'Rakefile', 'app/**/*', 'config/**/*', 'lib/**/*', 'public/**/*', 'vendor/**/*']

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency 'rails_admin-i18n', '~> 1.11'
  s.add_dependency 'ext_rails', version
  s.add_dependency 'ext_coffee', version
  s.add_dependency 'ext_chartkick', version
  s.add_dependency 'ext_bootstrap', version
  s.add_dependency 'kaminari', '>= 0.14', '< 2.0'
  s.add_dependency 'amoeba', '~> 3.0'
  s.add_dependency 'wicked_pdf', '~> 1.1'
  s.add_dependency 'wkhtmltopdf-binary', '~> 0.12.3.1'
  s.add_dependency 'remotipart', '~> 1.3'

  s.add_development_dependency 'bundler', '~> 1.0'
end
