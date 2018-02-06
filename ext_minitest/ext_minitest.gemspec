$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_minitest"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_minitest"
  s.summary     = "ExtMinitest"
  s.description = "ExtMinitest"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency 'minitest', '5.10.3' # https://github.com/seattlerb/minitest/issues/730
  s.add_dependency 'minitest-hooks'
  s.add_dependency 'minitest-spec-rails'
  s.add_dependency 'minitest-reporters'
  s.add_dependency 'maxitest'
  s.add_dependency 'mocha', '~> 1.3'
  s.add_dependency 'shoulda-context', '~> 1.2'
  s.add_dependency 'shoulda-matchers', '~> 3.1'
  s.add_dependency 'connection_pool'
  s.add_dependency 'rails-controller-testing'
  s.add_dependency 'sql_query'
  s.add_dependency 'ext_ruby', version
  s.add_dependency 'chronic'
  # TODO gem 'test-prof'
  # https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests
  # http://docs.seattlerb.org/minitest/Minitest/Expectations.html
end
