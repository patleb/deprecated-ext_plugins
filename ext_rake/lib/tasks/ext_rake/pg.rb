module ExtRake
  class Pg < ExtRake.config.parent_task.constantize
    include Psql

    def self.steps
      [:reload_settings_yml]
    end

    def self.pg_options
      ENV['PG_OPTIONS']
    end

    protected

    def with_config
      yield SettingsYml[:db_host],
        SettingsYml[:db_database],
        SettingsYml[:db_username],
        SettingsYml[:db_password]
    end
  end
end
