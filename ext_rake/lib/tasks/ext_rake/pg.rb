module ExtRake
  class Pg < ExtRake.config.parent_task.constantize
    include Notifier

    def self.args
      { db: ['--db=DB', 'DB type (ex.: --db=server would use ServerRecord connection'] }
    end

    def self.pg_options
      ENV['PG_OPTIONS']
    end

    def before_run
      super
      reload_settings_yml
    end

    protected

    def with_config
      db = ExtRake.config.db_config
      yield db[:host],
        db[:database],
        db[:username],
        db[:password]
    end
  end
end
