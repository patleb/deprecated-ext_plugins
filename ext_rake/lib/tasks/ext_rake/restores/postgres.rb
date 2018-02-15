module ExtRake
  class PostgresRestore < ExtRake.config.parent_task.constantize
    include Restore

    def self.args
      # TODO pg_restore --format=c
      {
        model:    ['--model=MODEL',     'Backup model'],
        version:  ['--version=VERSION', 'Backup version'],
        drop_all: ['--[no-]drop-all',   'Drop all before restore']
      }
    end

    def self.ignored_errors
      [
        /ERROR:.+does not exist/,
        'ERROR:  unrecognized configuration parameter "idle_in_transaction_session_timeout"',
        'ERROR:  must be owner of extension plpgsql',
        'ERROR:  must be owner of schema public',
        'ERROR:  schema "public" already exists',
        'WARNING:  no privileges could be revoked for "public"',
        'WARNING:  no privileges were granted for "public"',
      ]
    end

    def self.sanitized_lines
      { psql_url: /postgresql:.+:5432/ }
    end

    def self.backup_type
      'databases'
    end

    def self.psql_options
      ENV['PSQL_OPTIONS'].presence || \
        "--quiet "
    end

    def self.psql_url
      "postgresql://#{SettingsYml[:db_username]}:#{SettingsYml[:db_password]}@#{SettingsYml[:db_host]}:5432/#{SettingsYml[:db_database]}"
    end

    protected

    def restore_cmd
      drop_all = options.drop_all ? "#{drop_all_cmd} &&" : ''

      if Gem.win_platform?
        backup = extract_path.join("PostgreSQL.sql")
        %{#{drop_all} psql #{self.class.psql_options} "#{self.class.psql_url}" < "#{backup}"}
      else
        backup = extract_path.join("PostgreSQL.sql.gz")
        %{#{drop_all} cat "#{backup}" | gunzip | psql #{self.class.psql_options} "#{self.class.psql_url}"}
      end
    end

    def drop_all_cmd
      %{psql --quiet -c "DROP OWNED BY CURRENT_USER;" "#{self.class.psql_url}"}
    end
  end
end
