namespace :db do
  namespace :pg do
    desc "Dump the database to db/dump.pg"
    task :dump => :environment do
      with_config do |host, db, user, pwd|
        if ENV['ONLY'].present?
          only = ENV['ONLY'].split(',').reject(&:blank?).map{ |table| "--table='#{table}'" }.join(' ')
        end
        if ENV['SKIP'].present?
          skip = ENV['SKIP'].split(',').reject(&:blank?).map{ |table| "--exclude-table='#{table}'" }.join(' ')
        end
        sh <<~CMD, verbose: false
          export PGPASSWORD=#{pwd};
          pg_dump --host #{host} --username #{user} #{ENV['PG_OPTIONS']} --verbose --no-owner --no-acl --clean --format=c #{only} #{skip} #{db} > #{Rails.root}/db/dump.pg
        CMD
      end
    end

    desc "Restore the database from db/dump.pg"''
    task :restore => :environment do
      with_config do |host, db, user, pwd|
        if ENV['ONLY'].present?
          only = ENV['ONLY'].split(',').reject(&:blank?).map{ |table| "--table='#{table}'" }.join(' ')
        end
        sh <<~CMD, verbose: false
          export PGPASSWORD=#{pwd};
          pg_restore --verbose --host #{host} --username #{user} #{ENV['PG_OPTIONS']} --no-owner --no-acl #{only} --dbname #{db} #{Rails.root}/db/dump.pg
        CMD
      end
    end

    desc "Truncate the tables"
    task :truncate => :environment do
      with_config do |host, db, user, pwd|
        if ENV['ONLY'].blank?
          raise "comma separated tables must be specified through 'ONLY' environment variable"
        end
        only = ENV['ONLY'].split(',').reject(&:blank?).map do |table|
          <<-SQL
            TRUNCATE TABLE #{table};
            SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) + 1 FROM #{table}), 1), false);
          SQL
        end.gsub(/\n/, ' ').join(' ')
        sh <<~CMD, verbose: false
          psql -c "#{only}" postgres://#{user}:#{pwd}@#{host}/#{db}
        CMD
      end
    end

    # TODO http://manuelvanrijn.nl/blog/2012/01/18/convert-postgresql-to-sqlite/
    task :sqlite => :environment do
      ENV['PG_OPTIONS'] = '--data-only --inserts'
      invoke 'db:pg:dump'

      dump = "#{Rails.root}/db/dump.pg"
      tmp = Tempfile.new('dump.pg')
      begin
        tmp.puts 'BEGIN;'
        File.open(dump, 'r').each do |line|
          if line.match? /^(SET|SELECT pg_catalog\.setval)/
            # skip
          else
            line.gsub!(/'true'/, "'t'")
            line.gsub!(/'false'/, "'f'")
            tmp.puts line
          end
        end
        tmp.puts 'END;'
        tmp.close
        FileUtils.mv(tmp.path, dump)
      ensure
        tmp.close
        tmp.unlink
      end
    end

    private

    def with_config
      config = (defined?(ApplicationRecord) ? ApplicationRecord : ActiveRecord::Base).connection_config
      yield config[:host],
        config[:database],
        config[:username],
        config[:password]
    end
  end
end
