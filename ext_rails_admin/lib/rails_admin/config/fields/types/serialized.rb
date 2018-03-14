module RailsAdmin
  module Config
    module Fields
      module Types
        class Serialized < RailsAdmin::Config::Fields::Types::Text
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :formatted_value do
            self.class.yaml_dump(value) unless value.nil?
          end

          def parse_value(value)
            value.present? ? (self.class.yaml_load(value) || nil) : nil
          end

          def parse_input(params)
            params[name] = parse_value(params[name]) if params[name].is_a?(::String)
          end

          # Backwards-compatible with safe_yaml/load when SafeYAML isn't available.
          # Evaluates available YAML loaders at boot and creates appropriate method,
          # so no conditionals are required at runtime.
          def self.yaml_load(yaml)
            return @yaml.send(@load, yaml) if @yaml

            require 'safe_yaml/load'
            @yaml = SafeYAML
            @load = :load
          rescue LoadError
            if YAML.respond_to?(:safe_load)
              @yaml = YAML
              @load = :safe_load
            else
              raise LoadError.new "Safe-loading of YAML is not available. Please install 'safe_yaml' or install Psych 2.0+"
            end
          end

          def self.yaml_dump(object)
            YAML.dump(object)
          end
        end
      end
    end
  end
end
