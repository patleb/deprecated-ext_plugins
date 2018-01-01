module RailsAdmin
  module Config
    module Fields
      module Types
        class PgJson < RailsAdmin::Config::Fields::Types::Text
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :formatted_value do
            value.present? ? JSON.pretty_generate(value) : nil
          end

          def parse_input(params)
            if params[name].is_a?(::String)
              params[name] = (params[name].blank? ? nil : JSON.parse(params[name]))
            end
          end
        end
      end
    end
  end
end
