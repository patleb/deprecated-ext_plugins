module RailsAdmin
  module Config
    module Fields
      module Types
        class Enum < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :render do
            div class: bs_form_row do
              if !multiple?
                form.select(method_name, enum, { include_blank: true, selected: form_value }, html_attributes.reverse_merge(class: 'form-control'))
              else
                form.select(method_name, enum, { include_blank: true, selected: form_value, object: form.object },
                  html_attributes.reverse_merge(
                    class: "js_field_input js_select_multi form-control",
                    multiple: true
                  )
                )
              end
            end
          end

          register_instance_option :enum_method do
            @enum_method ||= bindings[:object].class.respond_to?("#{name}_enum") || bindings[:object].respond_to?("#{name}_enum") ? "#{name}_enum" : name
          end

          register_instance_option :enum do
            bindings[:object].class.respond_to?(enum_method) ? bindings[:object].class.send(enum_method) : bindings[:object].send(enum_method)
          end

          register_instance_option :pretty_value do
            if enum.is_a?(::Hash)
              enum.reject { |_k, v| v.to_s != value.to_s }.keys.first.to_s.presence || value.presence || ' - '
            elsif enum.is_a?(::Array) && enum.first.is_a?(::Array)
              enum.detect { |e| e[1].to_s == value.to_s }.try(:first).to_s.presence || value.presence || ' - '
            else
              value.presence || ' - '
            end
          end

          register_instance_option :multiple? do
            properties && [:serialized].include?(properties.type)
          end
        end
      end
    end
  end
end
