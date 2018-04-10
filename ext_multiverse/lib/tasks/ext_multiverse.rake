namespace :multiverse do
  if Rake::Task.task_defined?("multiverse:load_config")
    Rake::Task["multiverse:load_config"].clear

    task :load_config do
      # TODO compare with https://github.com/rails/rails/pull/32274/files
      if Multiverse.db
        paths = ([Rails.application] + Rails::Engine.subclasses).each_with_object({}) do |engine, memo|
          db_migrate_path = engine.config.paths['db/migrate'].to_ary.first
          memo[engine.root.join(db_migrate_path).to_s] = db_migrate_path
        end
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths.map! do |path|
          db_migrate_path = paths[path]
          if db_migrate_path
            path = path.sub db_migrate_path, Multiverse.migrate_path
          end
          path
        end
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
