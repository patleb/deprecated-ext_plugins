module ExtRake
  class PgRestore < Pg
    def self.steps
      [:pg_restore]
    end

    def self.args
      {
        name:     ['--name=NAME',         'Dump name (default to dump)'],
        includes: ['--includes=INCLUDES', 'Included tables'],
      }
    end

    def pg_restore
      with_config do |host, db, user, pwd|
        if options.includes.present?
          only = options.includes.split(',').reject(&:blank?).map{ |table| "--table='#{table}'" }.join(' ')
        end
        name = options.name.presence || 'dump'
        sh <<~CMD, verbose: false
          export PGPASSWORD=#{pwd};
          pg_restore --verbose --host #{host} --username #{user} #{self.class.pg_options} --no-owner --no-acl #{only} --dbname #{db} #{ExtRake.config.rails_root}/db/#{name}.pg
        CMD
      end
    end
  end
end
