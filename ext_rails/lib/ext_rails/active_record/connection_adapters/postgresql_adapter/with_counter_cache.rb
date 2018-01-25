# http://shuber.io/porting-activerecord-counter-cache-behavior-to-postgres/

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQLAdapter::WithCounterCache

      def create_function_counter_cache(force = false)
        if force || !function_exists?(:increment_counter)
          execute <<-SQL.strip_sql_script
            CREATE OR REPLACE FUNCTION increment_counter(table_name TEXT, column_name TEXT, id BIGINT, step INTEGER) RETURNS VOID AS $$
              DECLARE
                column_name TEXT := quote_ident(column_name);
                updates TEXT := column_name || '=' || column_name || '+' || step;
              BEGIN
                EXECUTE 'UPDATE ' || quote_ident(table_name) || ' SET ' || updates || ' WHERE id = $1'
                USING id;
              END;
            $$ LANGUAGE plpgsql;
          SQL
        end

        if force || !function_exists?(:counter_cache)
          execute <<-SQL.strip_sql_script
            CREATE OR REPLACE FUNCTION counter_cache() RETURNS TRIGGER AS $$
              DECLARE
                table_name TEXT := quote_ident(TG_ARGV[0]);
                counter_name TEXT := quote_ident(TG_ARGV[1]);
                fk_name TEXT := quote_ident(TG_ARGV[2]);
                fk_changed BOOLEAN := false;
                fk_value BIGINT;
                record RECORD;
              BEGIN
                IF TG_OP = 'UPDATE' THEN
                  record := NEW;
                  EXECUTE 'SELECT ($1).' || fk_name || ' != ' || '($2).' || fk_name
                  INTO fk_changed
                  USING OLD, NEW;
                END IF;
    
                IF TG_OP = 'DELETE' OR fk_changed THEN
                  record := OLD;
                  EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
                  PERFORM increment_counter(table_name, counter_name, fk_value, -1);
                END IF;
    
                IF TG_OP = 'INSERT' OR fk_changed THEN
                  record := NEW;
                  EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
                  PERFORM increment_counter(table_name, counter_name, fk_value, 1);
                END IF;
    
                RETURN record;
              END;
            $$ LANGUAGE plpgsql;
          SQL
        end
      end

      def drop_function_counter_cache
        exec_query("DROP FUNCTION IF EXISTS counter_cache()")
        exec_query("DROP FUNCTION IF EXISTS increment_counter(table_name TEXT, column_name TEXT, id BIGINT, step INTEGER)")
      end

      def add_counter_cache(table_with_counter, column_with_counter, watched_table, watched_foreign_key)
        trigger_name = "counter_cache_#{table_with_counter}_#{column_with_counter}"
        return if trigger_exists?(watched_table, trigger_name)

        sql = <<-SQL
          CREATE TRIGGER #{trigger_name}
            AFTER INSERT OR UPDATE OR DELETE ON #{watched_table}
            FOR EACH ROW EXECUTE PROCEDURE counter_cache('#{table_with_counter}', '#{column_with_counter}', '#{watched_foreign_key}');
        SQL

        exec_query(sql)
      end

      def remove_counter_cache(table_with_counter, column_with_counter, watched_table)
        exec_query("DROP TRIGGER IF EXISTS counter_cache_#{table_with_counter}_#{column_with_counter} ON #{watched_table}")
      end
    end
  end
end
