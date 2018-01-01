module RailsAdmin
  module Config
    module Fields
      module Types
        class FileUpload < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :render do
            file = form.object.send(method_name).presence
            html(
              div('.toggle', class: ('soft_hidden' if file && delete_method && form.object.send(delete_method) == '1')) do[
                pretty_value,
                form.file_field(name, html_attributes.reverse_merge(data: { fileupload: true }))
              ]end,
              if optional? && errors.blank? && file && delete_method
                html(
                  a('.btn.btn-info.btn-remove-image', href: '#', 'data-toggle': 'button', role: 'button', class: 'js_application_remove_file') do[
                    i('.icon-white.icon-trash'),
                    t('admin.actions.delete.menu').capitalize + " #{label.downcase}"
                  ]end,
                  form.check_box(delete_method, class: 'soft_hidden')
                )
              end,
              if cache_method
                form.hidden_field(cache_method)
              end
            )
          end

          register_instance_option :thumb_method do
            nil
          end

          register_instance_option :delete_method do
            nil
          end

          register_instance_option :cache_method do
            nil
          end

          register_instance_option :export_value do
            resource_url.to_s
          end

          register_instance_option :pretty_value do
            if value.presence
              url = resource_url
              if image
                thumb_url = resource_url(thumb_method)
                image_html = image_tag(thumb_url, class: 'img-thumbnail')
                url != thumb_url ? link_to(image_html, url, target: '_blank') : image_html
              else
                link_to(nil, url, target: '_blank')
              end
            end
          end

          register_instance_option :image? do
            (url = resource_url.to_s) && url.split('.').last =~ /jpg|jpeg|png|gif|svg/i
          end

          register_instance_option :allowed_methods do
            [method_name, delete_method, cache_method].compact
          end

          register_instance_option :html_attributes do
            {
              required: required? && !value.present?,
            }
          end

          # virtual class
          def resource_url
            raise('not implemented')
          end

          def virtual?
            true
          end
        end
      end
    end
  end
end
