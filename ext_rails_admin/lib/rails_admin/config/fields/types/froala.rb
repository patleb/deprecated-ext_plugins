module RailsAdmin
  module Config
    module Fields
      module Types
        class Froala < RailsAdmin::Config::Fields::Types::Text
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          # If you want to have a different toolbar configuration for wysihtml5
          # you can use a Ruby hash to configure these options:
          # https://github.com/jhollingworth/bootstrap-wysihtml5/#advanced
          register_instance_option :config_options do
            nil
          end

          register_instance_option :css_location do
            ActionController::Base.helpers.asset_path('froala_editor.min.css')
          end

          register_instance_option :js_location do
            ActionController::Base.helpers.asset_path('froala_editor.min.js')
          end

          register_instance_option :render do
            js_data = {
              csspath: css_location,
              jspath: js_location,
              config_options: config_options.to_json
            }
            form.text_area method_name, html_attributes.reverse_merge(data: { richtext: 'froala-wysiwyg', options: js_data.to_json }).reverse_merge(value: form_value)
          end

          [:config_options, :css_location, :js_location].each do |key|
            register_deprecated_instance_option :"froala_#{key}", key
          end
        end
      end
    end
  end
end
