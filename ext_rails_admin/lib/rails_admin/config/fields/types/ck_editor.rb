module RailsAdmin
  module Config
    module Fields
      module Types
        class CKEditor < RailsAdmin::Config::Fields::Types::Text
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          # If you want to have a different toolbar configuration for CKEditor
          # create your own custom config.js and override this configuration
          register_instance_option :config_js do
            nil
          end

          # Use this if you want to point to a cloud instances of CKeditor
          register_instance_option :location do
            nil
          end

          # Use this if you want to point to a cloud instances of the base CKeditor
          register_instance_option :base_location do
            "#{Rails.application.config.assets.prefix}/ckeditor/"
          end

          register_instance_option :render do
            js_data = {
              jspath: location ? location : base_location + "ckeditor.js",
              base_location: base_location,
              options: {
                customConfig: config_js ? config_js : base_location + "config.js"
              }
            }
            form.text_area method_name, html_attributes.reverse_merge(data: { richtext: 'ckeditor', options: js_data.to_json }).reverse_merge(value: form_value)
          end

          [:base_location, :config_js, :location].each do |key|
            register_deprecated_instance_option :"ckeditor_#{key}", key
          end
        end
      end
    end
  end
end
