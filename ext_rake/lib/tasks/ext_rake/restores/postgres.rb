module ExtRake
  class PostgresRestore < ExtRake.config.parent_task.constantize
    include Restore

    def self.args
      # TODO pg_restore --format=c
      {
        model:   ['--model=MODEL',     'Backup model'],
        version: ['--version=VERSION', 'Backup version'],
      }
    end

    def self.ignored_errors
      [
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

    protected

    def restore_cmd
      psql_url = "postgresql://#{SettingsYml[:db_username]}:#{SettingsYml[:db_password]}@#{SettingsYml[:db_host]}:5432/#{SettingsYml[:db_database]}"

      if Gem.win_platform?
        backup = extract_path.join("PostgreSQL.sql")
        %{psql #{self.class.psql_options} "#{psql_url}" < "#{backup}"}
      else
        backup = extract_path.join("PostgreSQL.sql.gz")
        %{cat "#{backup}" | gunzip | psql #{self.class.psql_options} "#{psql_url}"}
      end
    end
  end
end