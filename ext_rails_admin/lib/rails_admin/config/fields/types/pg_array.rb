module RailsAdmin
  module Config
    module Fields
      module Types
        class PgArray < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :formatted_value do
            value.join(', ') if value
          end
        end
      end
    end
  end
end
