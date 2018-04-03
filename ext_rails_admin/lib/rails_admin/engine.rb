module RailsAdmin
  class Engine < Rails::Engine
    isolate_namespace RailsAdmin

    # Initialize engine dependencies on wrapper application
    Gem.loaded_specs["ext_rails_admin"].dependencies.each do |d|
      begin
        require d.name
      rescue LoadError => e
        # Put exceptions here.
      end
    end

    config.action_dispatch.rescue_responses['RailsAdmin::ActionNotAllowed'] = :forbidden

    config.to_prepare do
      RailsAdmin::MainController.class_eval do
        include RailsAdmin::Main::WithExceptions
      end

      if RailsAdmin.config.with_admin_concerns
        (Rails::Engine.subclasses.map(&:root) << Rails.root).each do |root|
          Dir[root.join('app', 'models', 'admin', '**', '*.rb')].sort.reverse.each do |name|
            unless name.end_with?('_decorator.rb') || (!defined?(ExtMultiverse) && name.include?('app/models/admin/server/'))
              model = name.match(/app\/models\/admin\/(.+)\.rb/)[1].camelize.constantize
              model.include Admin
              model.include "Admin::#{model.name}".constantize
            end
          end
        end
        RailsAdmin.config.with_admin_concerns = false # do not reload in development --> restart the server
      end
    end

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), '../tasks/*.rake')].each { |f| load f }
    end
  end
end
