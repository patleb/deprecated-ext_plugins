require "ext_settings/configuration"

module ExtSettings
  class Engine < ::Rails::Engine
    require 'ext_rails'

    initializer 'ext_settings.append_migrations' do |app|
      unless ExtSettings.config.skip_migrations
        unless app.root.to_s.match(root.to_s)
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end
  end
end
