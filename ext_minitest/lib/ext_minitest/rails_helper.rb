# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rails/test_help'
require 'ext_minitest/spec'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

# See: https://gist.github.com/mperham/3049152
class ActiveRecord::Base
  # mattr_accessor :shared_connections
  # self.shared_connections = {}
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    # shared_connections[connection_config[:database]] ||= begin
    #   ConnectionPool::Wrapper.new(size: 1) { retrieve_connection }
    # end
    @@shared_connection || ConnectionPool::Wrapper.new(size: 1) { retrieve_connection }
  end
end

# TODO ext_multiverse
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

# hack a mutex in the query execution so that we don't
# get competing queries that can timeout and not get cleaned up
module MutexLockedQuerying
  @@semaphore = Mutex.new

  def async_exec(*)
    @@semaphore.synchronize { super }
  end
end

PG::Connection.prepend(MutexLockedQuerying)

ActiveSupport::TestCase.class_eval do
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  def file_config(path)
    Rails.root.join('test/configs', path)
  end

  def base_name
    self.class.name.match(/^(\w+)Test:{2}?/)[1]
  end
end

require_rel 'test_cases'
