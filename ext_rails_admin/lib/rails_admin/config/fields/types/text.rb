module RailsAdmin
  module Config
    module Fields
      module Types
        class Text < RailsAdmin::Config::Fields::Base
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          # TODO https://github.com/jaredreich/pell
          [:ckeditor, :ckeditor_base_location, :ckeditor_config_js, :ckeditor_location].each do |key|
            register_deprecated_instance_option key do
              raise("The 'field(:foo){ ckeditor true }' style DSL is deprecated. Please use 'field :foo, :ck_editor' instead.")
            end
          end

          [:codemirror, :codemirror_assets, :codemirror_config, :codemirror_css_location, :codemirror_js_location].each do |key|
            register_deprecated_instance_option key do
              raise("The 'field(:foo){ codemirror true }' style DSL is deprecated. Please use 'field :foo, :code_mirror' instead.")
            end
          end

          [:bootstrap_wysihtml5, :bootstrap_wysihtml5_config_options, :bootstrap_wysihtml5_css_location, :bootstrap_wysihtml5_js_location].each do |key|
            register_deprecated_instance_option key do
              raise("The 'field(:foo){ bootstrap_wysihtml5 true }' style DSL is deprecated. Please use 'field :foo, :wysihtml5' instead.")
            end
          end

          # TODO
          # register_instance_option :formatted_value do
          #   if value.present?
          #     simple_format(value, {}, sanitize: true)
          #   end
          # end

          register_instance_option :html_attributes do
            {
              required: required?,
              cols: '48',
              rows: '3',
            }
          end

          register_instance_option :render do
            div(class: 'input-group') do
              form.text_area method_name, html_attributes.reverse_merge(data: { richtext: false, options: {}.to_json }).reverse_merge({ value: form_value, class: 'form-control', required: required })
            end
          end
        end
      end
    end
  end
end
