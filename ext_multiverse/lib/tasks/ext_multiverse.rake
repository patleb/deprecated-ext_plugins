namespace :multiverse do
  if Rake::Task.task_defined?("multiverse:load_config")
    Rake::Task["multiverse:load_config"].clear

    task :load_config do
      # TODO compare with https://github.com/rails/rails/pull/32274/files
      if Multiverse.db
        paths = ([Rails.application.config] + Rails::Engine.subclasses.map(&:config)).map do |engine|
          db_migrate_path = engine.paths['db/migrate'].to_ary.first
          [engine.root.join(db_migrate_path).to_s, db_migrate_path]
        end.to_h
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths.map! do |path|
          path.sub paths[path], Multiverse.migrate_path
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
