module RailsAdmin
  module Config
    module Fields
      module Types
        class Boolean < RailsAdmin::Config::Fields::Base
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :view_helper do
            :check_box
          end

          register_instance_option :pretty_value do
            # TODO boolean field nil don't show icon on mobile
            case value
            when nil
              %(<span class='label label-default'>&#x2012;</span>)
            when false
              %(<span class='label label-danger'>&#x2718;</span>)
            when true
              %(<span class='label label-success'>&#x2713;</span>)
            end.html_safe
          end

          register_instance_option :export_value do
            value.inspect
          end

          register_instance_option :render do
            div '.checkbox' do
              label_ '.form_label_boolean' do
                checked = form_value.in?([true, '1'])
                form.send view_helper, method_name, html_attributes.reverse_merge(value: form_value, checked: checked, required: required)
              end
            end
          end

          # Accessor for field's help text displayed below input field.
          def generic_help
            ''
          end
        end
      end
    end
  end
end
