module RailsAdmin
  module ConceptsHelper
    def inline_create_concept(properties)
      model_name = @abstract_model.model.to_admin_param.tr(RailsAdmin::Config::NAMESPACE_SEPARATOR, '_')
      create_properties = @model_config.create.with(controller: controller, view: self, object: @abstract_model.model.new).visible_fields
      create_properties = properties.map do |property|
        if (index = create_properties.find_index{|p| p.name == property.name})
          create_properties[index].inline_create = true
          create_properties[index]
        else
          property
        end
      end

      tr '.js_inline_create_row' do[
        td do
          a '.btn.btn-default.btn-xs.js_inline_create_cancel' do
            i '.fa.fa-trash-o.fa-fw'
          end
        end,
        create_properties.map do |property|
          if property.inline_create && !property.read_only?
            name_attr = "#{model_name}[#{property.name}]"
            value_attr = property.form_value
            props = [name_attr, nil]
            props << value_attr.to_b if property.type == :boolean
            html_attr = property.html_attributes.reverse_merge(required: property.required, value: value_attr)
            td class: [property.css_class, property.type_css_class, 'js_inline_create_cell'] do
              send "#{property.view_helper}_tag", *props, html_attr
            end
          else
            td class: [property.css_class, property.type_css_class] do
              ' - '
            end
          end
        end,
        td('.last.links') do
          ul '.list-inline' do
            li do
              a '.btn.btn-primary.btn-xs.js_inline_create_save' do
                i '.icon-white.icon-ok'
              end
            end
          end
        end
      ]end
    end

    def inline_update_concept(object, property)
      model, id, name = object.class.to_admin_param, object.id, property.name
      model_name = model.tr(RailsAdmin::Config::NAMESPACE_SEPARATOR, '_')

      name_attr = "#{model_name}[#{property.name}]"
      value_attr = property.form_value
      props = [name_attr, nil]
      props << value_attr.to_b if property.type == :boolean
      html_attr = property.html_attributes.reverse_merge(id: "#{id}_#{name}", required: property.required, value: value_attr, readonly: true)

      td class: [property.css_class, property.type_css_class, 'js_inline_update_wrapper', 'js_inline_update_readonly'] do
        send "#{property.view_helper}_tag", *props, html_attr
      end
    end
  end
end
