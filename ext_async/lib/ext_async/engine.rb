require "ext_async/configuration"

module ExtAsync
  class Engine < ::Rails::Engine
    require 'ext_rails'
    require 'ext_rake'
    require 'ext_shell'

    config.before_configuration do |app|
      app.config.active_job.queue_adapter = :inline
    end

    initializer 'ext_async.append_migrations' do |app|
      unless ExtAsync.config.skip_migrations
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end

    config.after_initialize do |app|
      app.routes.prepend do
        get '_batch/exists' => 'batch#exists', as: 'batch_exists'
        get '_batch/enqueue' => 'batch#enqueue', as: 'batch_enqueue'

        (Rails::Engine.subclasses.map(&:root) << Rails.root).each do |root|
          Dir[root.join('app', 'controllers', 'async', '**', '*_controller.rb')].each do |name|
            controller = name.match(/app\/controllers\/(.+)\.rb/)[1].camelize.safe_constantize
            if controller
              async_path = controller.controller_path
              get "_#{async_path}" => "#{async_path}#perform_now", as: async_path.underscore
            end
          end
        end
      end
    end
  end
end
