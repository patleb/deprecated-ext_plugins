module RailsAdmin
  module Config
    module Fields
      module Types
        class PgHstore < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :formatted_value do
            value.to_yaml
          end

          def parse_input(params)
            params[name] = if params[name].blank?
              nil
            else
              YAML.load(params[name])
            end
          end
        end
      end
    end
  end
end
