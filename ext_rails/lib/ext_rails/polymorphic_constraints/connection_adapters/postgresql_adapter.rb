require 'polymorphic_constraints/connection_adapters/postgresql_adapter'

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  def generate_upsert_constraints(relation, associated_table, polymorphic_models)
    associated_table = associated_table.to_s
    polymorphic_models = polymorphic_models.map(&:to_s)

    sql = <<-SQL
      CREATE FUNCTION check_#{relation}_upsert_integrity()
        RETURNS TRIGGER AS '
          BEGIN
            IF (NEW.#{relation}_id IS NULL OR NEW.#{relation}_type IS NULL) THEN

              RETURN NEW;
    SQL

    polymorphic_models.each do |polymorphic_model|
      model = polymorphic_model.classify
      sql << <<-SQL
        ELSEIF (NEW.#{relation}_type = ''#{model}'' OR NEW.#{relation}_type LIKE ''#{model}::%'') AND
               EXISTS (SELECT id FROM #{model.constantize.table_name}
                       WHERE id = NEW.#{relation}_id) THEN

          RETURN NEW;
      SQL
    end

    sql << <<-SQL
        ELSE
          RAISE EXCEPTION ''Polymorphic record not found.
                            No % model with id %.'', NEW.#{relation}_type, NEW.#{relation}_id;
          RETURN NULL;
        END IF;
      END'
      LANGUAGE plpgsql;

      CREATE TRIGGER check_#{relation}_upsert_integrity_trigger
        BEFORE INSERT OR UPDATE ON #{associated_table}
        FOR EACH ROW
        EXECUTE PROCEDURE check_#{relation}_upsert_integrity();
    SQL

    strip_non_essential_spaces(sql)
  end

  def generate_delete_constraints(relation, associated_table, polymorphic_models)
    associated_table = associated_table.to_s
    polymorphic_models = polymorphic_models.map(&:to_s)

    model = polymorphic_models.first.classify
    sql = <<-SQL
      CREATE FUNCTION check_#{relation}_delete_integrity()
        RETURNS TRIGGER AS '
          BEGIN
            IF TG_TABLE_NAME = ''#{model.constantize.table_name}'' AND
               EXISTS (SELECT id FROM #{associated_table}
                       WHERE (#{relation}_type = ''#{model}'' OR #{relation}_type LIKE ''#{model}::%'')
                       AND #{relation}_id = OLD.id) THEN

              RAISE EXCEPTION ''Polymorphic reference exists.
                                There are records in #{associated_table} that refer to the table % with id %.
                                You must delete those records of table #{associated_table} first.'', TG_TABLE_NAME, OLD.id;
              RETURN NULL;
    SQL

    polymorphic_models[1..-1].each do |polymorphic_model|
      model = polymorphic_model.classify
      sql << <<-SQL
        ELSEIF TG_TABLE_NAME = ''#{model.constantize.table_name}'' AND
               EXISTS (SELECT id FROM #{associated_table}
                       WHERE (#{relation}_type = ''#{model}'' OR #{relation}_type LIKE ''#{model}::%'')
                       AND #{relation}_id = OLD.id) THEN

          RAISE EXCEPTION ''Polymorphic reference exists.
                            There are records in #{associated_table} that refer to the table % with id %.
                            You must delete those records of table #{associated_table} first.'', TG_TABLE_NAME, OLD.id;
          RETURN NULL;
      SQL
    end

    sql << <<-SQL
          ELSE
            RETURN OLD;
          END IF;
        END'
      LANGUAGE plpgsql;
    SQL

    polymorphic_models.each do |polymorphic_model|
      table_name = polymorphic_model.classify.constantize.table_name

      sql << <<-SQL
        CREATE TRIGGER check_#{relation}_#{table_name}_delete_integrity_trigger
          BEFORE DELETE ON #{table_name}
          FOR EACH ROW
          EXECUTE PROCEDURE check_#{relation}_delete_integrity();
      SQL
    end

    strip_non_essential_spaces(sql)
  end
end
