require "ext_bootstrap/configuration"

module ExtBootstrap
  class Engine < ::Rails::Engine
   
    # Initialize engine dependencies on wrapper application
    Gem.loaded_specs["ext_bootstrap"].dependencies.each do |d|
      begin
        require d.name unless d.name == 'sass-rails'
      rescue LoadError => e
        # Put exceptions here.
      end
    end

    initializer 'ext_bootstrap.assets.paths' do |app|
      app.config.assets.paths << root.join('node_modules')
    end

    initializer 'ext_bootstrap.assets.precompile' do |app|
      app.config.assets.precompile << 'roboto-fontface/fonts/*'
    end

    ActiveSupport.on_load(:action_controller) do
      ::ActionController::Base.class_eval do
        helper ExtBootstrap::Engine.helpers
      end
    end
  end
end
