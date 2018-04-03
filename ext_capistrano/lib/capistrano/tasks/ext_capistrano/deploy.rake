namespace :deploy do
  if Rake::Task.task_defined?("deploy:compile_assets")
    Rake::Task["deploy:compile_assets"].clear

    desc 'Compile assets'
    task :compile_assets => [:set_rails_env] do
      if fetch(:precompile_local)
        # TODO https://github.com/rails/sprockets/issues/467
        invoke 'deploy:assets:precompile_local'
      else
        invoke 'deploy:assets:precompile'
      end
      invoke 'deploy:assets:backup_manifest'
    end

    namespace :assets do
      desc "Precompile assets locally and then rsync to web servers"
      task :precompile_local do
        on release_roles(fetch(:assets_roles)) do
          # compile assets locally
          run_locally do
            db = YAML.load_file('config/database.yml')['development']
            db_connection = "#{db['adapter']}://#{db['username']}:#{db['password']}@#{db['host']}/#{db['database']}"
            execute "RAILS_ENV=#{fetch(:stage)} DATABASE_URL=#{db_connection} bundle exec rake assets:precompile"
          end

          # rsync to each server
          local_dir = "./public/assets/"
          # this needs to be done outside run_locally in order for host to exist
          remote_dir = "#{host.user}@#{host.hostname}:#{release_path}/public/assets/"

          run_locally { execute "rsync -av --delete #{local_dir} #{remote_dir}" }

          # clean up
          run_locally { execute "rm -rf #{local_dir}" }
        end
      end
    end
  end

  desc 'Runs rake db:migrate DB=server'
  task :server_migrate => [:set_rails_env] do
    on release_roles fetch(:db_server_roles) do
      info '[deploy:migrate] Run `rake db:migrate DB=server`'
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:migrate', 'DB=server'
        end
      end
    end
  end
  after 'deploy:migrate', 'deploy:server_migrate'

  # TODO https://superuser.com/questions/19563/how-do-i-skip-the-known-host-question-the-first-time-i-connect-to-a-machine-vi
  desc 'Full server deploy after provisioning'
  task :push do
    invoke 'dns:set_localhost'
    invoke 'nginx:push'
    invoke 'deploy:app:push'
    invoke 'monit:push'
    invoke 'monit:restart'
  end

  namespace :app do
    desc 'App server deploy after provisioning'
    task :push do
      %i(
        deploy:check:directories
        deploy:check:linked_dirs
        deploy:check:make_linked_dirs
        secrets:push
        logrotate:push
        nginx:app:push
        nginx:app:enable
        db:pg:create_user
        db:pg:create_database
        db:pg:create_server_database
        db:pg:set_superuser
        deploy
        whenever:create_cron_log
      ).each do |task|
        invoke task
      end
    end
  end
end
