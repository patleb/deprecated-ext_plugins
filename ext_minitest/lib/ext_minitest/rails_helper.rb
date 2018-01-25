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
    Rails.root.join('test/config', path)
  end
end

ActionController::TestCase.class_eval do
  let(:controller){ self.class.name.match(/^(\w+)Test::/)[1].constantize.new }

  def method_missing(name, *args, &block)
    controller.__send__(name, *args, &block)
  end

  def respond_to_missing?(name, include_private = false)
    controller.respond_to?(name, include_private) || super
  end

  protected

  def params=(values)
    controller.stubs(:params).returns(values)
  end

  def instance_variable(name)
    controller.send(:instance_variable_get, name)
  end
end

module PostgreSQL
  class TestCase < ActiveSupport::TestCase
    include Minitest::Hooks

    class_attribute :migrations_root, :migrations, :adapter, :sql_root

    self.use_transactional_tests = false
    self.migrations_root = Rails.root.join('db/migrate')
    self.migrations = []
    self.adapter = ActiveRecord::Base
    self.sql_root = '/test/models/sql'

    delegate :connection, to: :adapter

    class TestQuery < ::SqlQuery
      def initialize(*_)
        super
        @name = @sql_filename.to_s.gsub(/\W/, '_')
      end

      def setup
        @output ||= ''
        @output << <<~SQL
          CREATE OR REPLACE FUNCTION test_setup_#{@name}() RETURNS VOID AS $$
          BEGIN
            IF EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'test_teardown_#{@name}') THEN
              PERFORM test_teardown_#{@name}();
            END IF;
        SQL

        yield

        @output << <<~SQL
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def teardown
        @output ||= ''
        @output << <<~SQL
          CREATE OR REPLACE FUNCTION test_teardown_#{@name}() RETURNS VOID AS $$
          BEGIN
        SQL

        yield

        @output << <<~SQL
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def sql
        @output ||= ''
        @output << ERB.new(File.read(file_path), nil, nil, "@output").result(binding)
      end

      def run_suite
        execute
        connection.execute("SELECT * FROM test_run_suite('#{@name}')").entries.each do |entry|
          entry['error_message'].must_equal 'OK'
        end
      end
    end

    before(:all) do
      procedures = connection.select_values(<<-SQL)
        SELECT proname FROM pg_proc 
        WHERE proname LIKE 'test\_setup\_%'
          OR  proname LIKE 'test\_precondition\_%'
          OR  proname LIKE 'test\_case\_%'
          OR  proname LIKE 'test\_postcondition\_%'
          OR  proname LIKE 'test\_teardown\_%'
      SQL

      procedures.each do |procedure|
        connection.exec_query "DROP FUNCTION IF EXISTS #{procedure}()"
      end

      migrations.each do |migration|
        require migrations_root.join(migration)
        _number, name = migration.split('_', 2)
        migration = name.camelize.constantize.new
        migration.down
        migration.up
      end

      TestQuery.configure do |config|
        config.path = sql_root
      end
    end
  end
end
