module RailsAdmin
  module Config
    module Sections
      # Configuration of the navigation view
      class Export < RailsAdmin::Config::Sections::Base
        register_instance_option :extra_formats do
          [:json, :xml]
        end
      end
    end
  end
end
