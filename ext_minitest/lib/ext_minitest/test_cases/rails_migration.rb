module RailsMigration
  class TestCase < ActiveSupport::TestCase
    include Minitest::Hooks

    class_attribute :migrations_root, :migrations, :adapter, :sql_root

    self.use_transactional_tests = false
    self.migrations_root = Rails.root.join('db/migrate')
    self.migrations = []
    self.adapter = ActiveRecord::Base
    self.sql_root = 'test/migrations/sql'

    delegate :connection, to: :adapter

    class TestQuery < ::SqlQuery
      def initialize(*_)
        super
        @name = @sql_filename.to_s.gsub(/\W/, '_')
      end

      def setup
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
        @output ||= begin
          @output = ''
          ERB.new(File.read(file_path), nil, nil, "@output").result(binding)
        end
      end

      def prepared_for_logs
        sql.strip_sql_script
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
        config.path = sql_root.start_with?('/') ? sql_root : "/#{sql_root}"
      end
    end
  end
end
