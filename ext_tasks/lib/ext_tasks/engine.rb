require "ext_tasks/configuration"

module ExtTasks
  class Engine < ::Rails::Engine
    require 'ext_rails'
    require 'ext_rake'
    require 'ext_globals'
    require 'ext_mail'
    require 'ext_async'

    config.before_configuration do
      Rails.application.send :define_singleton_method, :all_rake_tasks do
        @_all_rake_tasks ||= begin
          ::Rake::TaskManager.record_task_metadata = true
          Rails.application.load_tasks
          tasks = ::Rake.application.instance_variable_get('@tasks')
          unless ExtTasks.config.keep_install_migrations
            tasks.each do |t|
              if (task_name = t.first).end_with? ':install:migrations'
                tasks.delete(task_name)
              end
            end
          end
          tasks
        end
      end
    end
  end
end
