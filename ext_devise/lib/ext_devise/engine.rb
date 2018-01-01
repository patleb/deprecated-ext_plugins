require "ext_devise/configuration"

module ExtDevise
  class Engine < ::Rails::Engine
    require "devise"
    require "devise-bootstrap-views"
    require 'devise-i18n'
    require 'ext_rails'

    initializer 'ext_devise.append_migrations' do |app|
      unless ExtDevise.config.skip_migrations
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end

    config.after_initialize do
      index = ActionController::Base.view_paths.paths.index{ |p| p.to_s.include? '/devise-' }
      engines = []
      loop do
        engine = ActionController::Base.view_paths.pop
        if engine.to_path.include? '/ext_devise'
          ActionController::Base.view_paths.insert(index, engine)
          break
        end
        engines << engine
      end
      while engine = engines.pop
        ActionController::Base.view_paths << engine
      end
    end
  end
end
