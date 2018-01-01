module RailsAdmin
  module Config
    module Fields
      module Types
        class ForeignKey < RailsAdmin::Config::Fields::Base
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :pretty_value do
            a '.pjax', value, href: rails_admin.show_path(model_name: model_name, id: value)
          end

          register_instance_option :export_value do
            value
          end

          register_instance_option :model_name do
            name.to_s.sub(/_id$/, '')
          end
        end
      end
    end
  end
end
