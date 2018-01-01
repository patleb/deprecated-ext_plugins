# http://shuber.io/porting-activerecord-counter-cache-behavior-to-postgres/

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQLAdapter::WithCounterCache

      def create_function_counter_cache(force = false)
        if force || !function_exists?(:increment_counter)
          sql = <<-SQL
            CREATE OR REPLACE FUNCTION increment_counter(table_name text, column_name text, id integer, step integer) RETURNS VOID AS $$
              DECLARE
                table_name text := quote_ident(table_name);
                column_name text := quote_ident(column_name);
                conditions text := ' WHERE id = $1';
                updates text := column_name || '=' || column_name || '+' || step;
              BEGIN
                EXECUTE 'UPDATE ' || table_name || ' SET ' || updates || conditions
                USING id;
              END;
            $$ LANGUAGE plpgsql;
          SQL

          exec_query(sql)
        end

        if force || !function_exists?(:counter_cache)
          sql = <<-SQL
            CREATE OR REPLACE FUNCTION counter_cache() RETURNS trigger AS $$
              DECLARE
                table_name text := quote_ident(TG_ARGV[0]);
                counter_name text := quote_ident(TG_ARGV[1]);
                fk_name text := quote_ident(TG_ARGV[2]);
                fk_changed boolean := false;
                fk_value integer;
                record record;
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

          exec_query(sql)
        end
      end

      def drop_function_counter_cache
        exec_query("DROP FUNCTION IF EXISTS counter_cache()")
        exec_query("DROP FUNCTION IF EXISTS increment_counter(table_name text, column_name text, id integer, step integer)")
      end

      def add_counter_cache(table_with_counter, column_with_counter, watched_table, watched_foreign_key)
        trigger_name = "update_#{table_with_counter}_#{column_with_counter}"
        return if trigger_exists?(watched_table, trigger_name)

        sql = <<-SQL
          CREATE TRIGGER #{trigger_name}
            AFTER INSERT OR UPDATE OR DELETE ON #{watched_table}
            FOR EACH ROW EXECUTE PROCEDURE counter_cache('#{table_with_counter}', '#{column_with_counter}', '#{watched_foreign_key}');
        SQL

        exec_query(sql)
      end

      def remove_counter_cache(table_with_counter, column_with_counter, watched_table)
        exec_query("DROP TRIGGER IF EXISTS update_#{table_with_counter}_#{column_with_counter} ON #{watched_table}")
      end
    end
  end
end
