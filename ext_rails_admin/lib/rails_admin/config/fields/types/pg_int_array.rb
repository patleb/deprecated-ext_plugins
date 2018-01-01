module RailsAdmin
  module Config
    module Fields
      module Types
        class PgIntArray < RailsAdmin::Config::Fields::Types::PgArray
          RailsAdmin::Config::Fields::Types.register(self)

          def parse_input(params)
            if params[name].is_a?(::String)
              params[name] = params[name].split(',').collect{|x| x.to_i}
            end
          end
        end
      end
    end
  end
end
