module ExtRake
  class RestorePostgres < Restore
    def self.args
      {
        model:      ['--model=MODEL',     'Backup model'],
        version:    ['--version=VERSION', 'Backup version'],
        drop_all:   ['--[no-]drop-all',   'Drop all before restore'],
        pg_restore: ['--[no-]pg-restore', 'Use pg_restore'],
        db:         ['--db=DB',           'DB type (ex.: --db=server would use ServerRecord connection'],
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

    def self.pg_restore_options
      ENV['PG_RESTORE_OPTIONS'].presence
    end

    protected

    def restore_cmd
      drop_all = options.drop_all ? "#{drop_all_cmd} &&" : ''

      if Gem.win_platform?
        raise NoWindowsSupport if options.pg_restore

        backup = extract_path.join("PostgreSQL.sql")
        %{#{drop_all} psql #{self.class.psql_options} "#{ExtRake.config.db_url}" < "#{backup}"}
      else
        backup = extract_path.join("PostgreSQL.sql.gz")
        if options.pg_restore
          %{#{drop_all} zcat "#{backup}" | pg_restore #{self.class.pg_restore_options} -d "#{ExtRake.config.db_url}"}
        else
          %{#{drop_all} zcat "#{backup}" | psql #{self.class.psql_options} "#{ExtRake.config.db_url}"}
        end
      end
    end

    def drop_all_cmd
      %{psql --quiet -c "DROP OWNED BY CURRENT_USER;" "#{ExtRake.config.db_url}"}
    end
  end
end
