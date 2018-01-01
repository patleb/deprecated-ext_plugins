require "ext_globals/configuration"

module ExtGlobals
  class Engine < ::Rails::Engine
    require 'ext_rails'

    initializer 'ext_globals.append_migrations' do |app|
      unless ExtGlobals.config.skip_migrations
        unless app.root.to_s.match(root.to_s)
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end
  end
end
