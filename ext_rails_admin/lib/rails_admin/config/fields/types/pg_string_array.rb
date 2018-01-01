module RailsAdmin
  module Config
    module Fields
      module Types
        class PgStringArray < RailsAdmin::Config::Fields::Types::PgArray
          RailsAdmin::Config::Fields::Types.register(self)

          def parse_input(params)
            if params[name].is_a?(::String)
              params[name] = params[name].split(',').reject(&:blank?).map(&:strip).compact
            end
          end

          register_instance_option :html_attributes do
            {
              cols: '48',
              rows: '3'
            }
          end

          register_instance_option :partial do
            :form_text
          end
        end
      end
    end
  end
end
