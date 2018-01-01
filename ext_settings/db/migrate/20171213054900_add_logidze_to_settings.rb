class AddLogidzeToSettings < ActiveRecord::Migration[5.1]
  require 'logidze/migration'
  include Logidze::Migration

  # rails generate logidze:model Setting --limit=20 --backfill
  def up

    add_column :settings, :log_data, :jsonb


    execute <<-SQL
      CREATE TRIGGER logidze_on_settings
      BEFORE UPDATE OR INSERT ON settings FOR EACH ROW
      WHEN (coalesce(#{current_setting('logidze.disabled')}, '') <> 'on')
      EXECUTE PROCEDURE logidze_logger(20, 'updated_at');
    SQL


    execute <<-SQL
      UPDATE settings as t
      SET log_data = logidze_snapshot(to_jsonb(t), 'updated_at');
    SQL

  end

  def down

    execute "DROP TRIGGER IF EXISTS logidze_on_settings on settings;"


    remove_column :settings, :log_data


  end
end
