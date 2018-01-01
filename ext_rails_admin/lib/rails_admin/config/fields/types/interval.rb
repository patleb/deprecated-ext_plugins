module RailsAdmin
  module Config
    module Fields
      module Types
        class Interval < RailsAdmin::Config::Fields::Base
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)
          # TODO implementation
        end
      end
    end
  end
end
