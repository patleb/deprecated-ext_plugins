module ExtRake
  class PgDropAll < Pg
    def self.steps
      super + [:psql_drop_all]
    end

    def psql_drop_all
      sh <<~CMD, verbose: false
        psql --quiet -c "DROP OWNED BY CURRENT_USER;" "#{self.class.psql_url}"
      CMD
    end
  end
end
