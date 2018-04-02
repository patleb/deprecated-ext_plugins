namespace :multiverse do
  if Rake::Task.task_defined?("multiverse:load_config")
    Rake::Task["multiverse:load_config"].clear

    task :load_config do
      if Multiverse.db
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths.map!{ |path| path.sub 'db/migrate', Multiverse.migrate_path }
        ActiveRecord::Tasks::DatabaseTasks.db_dir = [Multiverse.db_dir]
        Rails.application.paths["db/seeds.rb"] = ["#{Multiverse.db_dir}/seeds.rb"]

        if ActiveRecord::Tasks::DatabaseTasks.database_configuration
          new_config = {}
          Rails.application.config.database_configuration.each do |env, config|
            if env.start_with?("#{Multiverse.db}_")
              new_config[env.sub("#{Multiverse.db}_", "")] = config
            end
          end
          ActiveRecord::Tasks::DatabaseTasks.database_configuration.merge!(new_config)
        end

        # load config
        ActiveRecord::Base.configurations = ActiveRecord::Tasks::DatabaseTasks.database_configuration || {}
        ActiveRecord::Migrator.migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

        ActiveRecord::Base.establish_connection

        # need this to run again if environment is loaded afterwards
        Rake::Task["db:load_config"].reenable
      end
    end
  end
end
