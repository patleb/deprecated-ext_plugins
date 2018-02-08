namespace :db do
  namespace :pg do
    desc "Dump the database to db/dump.pg"
    task :dump, [:plain] => :environment do |t, args|
      with_config do |host, db, user, pwd|
        unless args[:plain] == 'plain'
          format_c = '--format=c'
        end
        if ENV['ONLY'].present?
          only = ENV['ONLY'].split(',').reject(&:blank?).map{ |table| "--table='#{table}'" }.join(' ')
        end
        if ENV['SKIP'].present?
          skip = ENV['SKIP'].split(',').reject(&:blank?).map{ |table| "--exclude-table='#{table}'" }.join(' ')
        end
        sh <<~CMD, verbose: false
          export PGPASSWORD=#{pwd};
          pg_dump --host #{host} --username #{user} #{ENV['OPTIONS']} --verbose --clean --no-owner --no-acl #{format_c} #{only} #{skip} #{db} > #{Rails.root}/db/dump.pg
        CMD
      end
    end

    desc "Restore the database from db/dump.pg"
    task :restore, [:disable_triggers] => :environment do |t, args|
      if args[:disable_triggers] == 'disable_triggers'
        disable_triggers = '--disable-triggers'
      end
      with_config do |host, db, user, pwd|
        sh <<~CMD, verbose: false
          export PGPASSWORD=#{pwd};
          pg_restore --verbose --host #{host} --username #{user} #{ENV['OPTIONS']} --clean --no-owner --no-acl #{disable_triggers} --dbname #{db} #{Rails.root}/db/dump.pg
        CMD
      end
    end

    # TODO http://manuelvanrijn.nl/blog/2012/01/18/convert-postgresql-to-sqlite/
    task :sqlite => :environment do
      ENV['OPTIONS'] = '--data-only --inserts'
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
