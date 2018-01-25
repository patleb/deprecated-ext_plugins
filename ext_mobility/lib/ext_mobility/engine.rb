require "ext_mobility/configuration"

module ExtMobility
  class Engine < ::Rails::Engine
    require 'ext_rails'
    require 'mobility'

    initializer 'ext_mobility.append_migrations' do |app|
      unless ExtMobility.config.skip_migrations
        unless app.root.to_s.match(root.to_s)
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end
  end
end
