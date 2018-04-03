# TODO gzip and upload/download

namespace :db do
  namespace :pg do
    def psql(*args)
      test :sudo, "-u postgres psql -d postgres", *args
    end

    desc 'create user'
    task :create_user, [:username, :password] do |t, args|
      on release_roles fetch(:db_roles) do
        user = args[:username].presence || SettingsYml[:db_username]
        next if psql '-tAc', %{"SELECT 1 FROM pg_roles WHERE rolname='#{user}';" | grep -q 1}
        pwd = args[:password].presence || SettingsYml[:db_password]
        if psql '-c', %{"CREATE USER #{user} WITH PASSWORD '#{pwd}';"}
          info 'create user successful'
        else
          error "cannot create user [#{user}]"
          exit 1
        end
      end
    end

    desc 'set superuser'
    task :set_superuser, [:username] do |t, args|
      on release_roles fetch(:db_roles) do
        next if fetch(:stage) != :vagrant
        user = args[:username].presence || SettingsYml[:db_username]
        if psql '-c', %{"ALTER USER #{user} WITH SUPERUSER;"}
          info 'superuser successful'
        else
          error "cannot set superuser [#{user}]"
          exit 1
        end
      end
    end

    desc 'create database'
    task :create_database, [:database, :username] do |t, args|
      on release_roles fetch(:db_roles) do
        db = args[:database].presence || SettingsYml[:db_database]
        next if psql '-tAc', %{"SELECT 1 FROM pg_database WHERE datname='#{db}';" | grep -q 1}
        user = args[:username].presence || SettingsYml[:db_username]
        if psql '-c', %{"CREATE DATABASE #{db} OWNER #{user};"}
          info 'create database successful'
        else
          error "cannot create database #{db}"
          exit 1
        end
      end
    end

    desc 'create server database'
    task :create_server_database do
      on release_roles fetch(:db_server_roles) do
        invoke! 'db:pg:create_database', "server_#{SettingsYml[:db_database]}"
      end
    end
  end
end
