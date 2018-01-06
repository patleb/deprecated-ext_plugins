require "ext_coffee/configuration"

module ExtCoffee
  class Engine < ::Rails::Engine
    # Initialize engine dependencies on wrapper application
    Gem.loaded_specs["ext_coffee"].dependencies.each do |d|
      begin
        require d.name
      rescue LoadError => e
        # Put exceptions here.
      end
    end

    initializer 'ext_coffee.execjs' do
      if Rails.env.development? || Rails.env.test?
        require 'alaska/runtime'

        ExecJS.runtime = Alaska::Runtime.new(debug: true)
      end
    end
  end
end
