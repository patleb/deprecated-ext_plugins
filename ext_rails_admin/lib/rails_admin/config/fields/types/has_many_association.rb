module RailsAdmin
  module Config
    module Fields
      module Types
        class HasManyAssociation < RailsAdmin::Config::Fields::Association
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          # orderable associated objects
          register_instance_option :orderable do
            false
          end

          def method_name
            nested_form ? "#{super}_attributes".to_sym : "#{super.to_s.singularize}_ids".to_sym # name_ids
          end

          # Reader for validation errors of the bound object
          def errors
            m.errors[name]
          end

          def render_nested
            config = associated_model_config
            abstract_model = config.abstract_model
            selected = selected_objects(abstract_model)
            can_create, can_destroy = !nested_form[:update_only], nested_form[:allow_destroy]
            errors_index = selected.find_index{ |object| object.errors.any? }
            opened = active? || errors_index
            association_id = form.nested_form_dom_id(name)

            div '.js_nested_form_wrapper' do[
              div('.controls.col-sm-10') do[
                div('.btn-group') do[
                  a(".btn.btn-#{errors_index ? 'danger' : 'info'}.js_nested_form_toggle#{'.active' if opened}#{'.js_disabled' if selected.empty?}", href: '#') do
                    i ".icon-white.#{opened ? 'icon-chevron-down' : 'icon-chevron-right'}"
                  end,
                  if can_create && inline_add
                    form.link_to_add name, class: 'btn btn-info' do
                      html(
                        i('.icon-plus.icon-white'),
                        wording_for(:link, :new, associated_model_config.abstract_model)
                      )
                    end
                  end
                ]end,
                form.errors_for(self),
                form.help_for(self),
                ul(".nav.nav-tabs", style: ('display:none' unless opened)) do
                  selected.map.with_index do |object, i|
                    li class: [('active' if i == errors_index), ('has-error' if object.errors.any?)].compact do
                      a href: "#tab_#{association_id}_#{i}", data: { toggle: 'tab' } do
                        object.send(associated_object_label_method)
                      end
                    end
                  end
                end,
              ]end,
              div(".tab-content", style: ('display:none' unless opened)) do
                if selected.empty?
                  template_object = m.send(name).build
                  form.fields_for name, template_object do |f|
                    html(
                      f.link_to_remove(name) do
                        f.span ".btn.btn-sm.btn-default", f.i('.icon-trash')
                      end,
                      f.generate(action: :nested, model_config: associated_model_config, nested_in: self)
                    )
                  end
                end
                selected.map.with_index do |object, i|
                  div "#tab_#{association_id}_#{i}.tab-pane.fade#{'.active.in' if i == errors_index}" do
                    form.fields_for name, object do |f|
                      is_template = f.options[:nested_form_template] || object.new_record?
                      html(
                        if can_destroy || is_template
                          f.link_to_remove name do
                            f.span ".btn.btn-sm.btn-#{is_template ? 'default' : 'danger'}", f.i('.icon-trash')
                          end
                        end,
                        f.generate(action: :nested, model_config: associated_model_config, nested_in: self)
                      )
                    end
                  end
                end
              end
            ]end
          end

          def render_filtering
            collection, selected_ids, new_params, abstract_model, data_js, remote = filtering_options
            field_id = form.dom_id(self)
            html(
              div(class: bs_form_row) do
                form.select(method_name, collection, { include_blank: true, selected: selected_ids, object: form.object },
                  html_attributes.reverse_merge(
                    class: "js_field_input js_select_multi#{'_remote' if remote} form-control",
                    data: { js: data_js.to_json },
                    multiple: true
                  )
                )
              end,
              ul(".list-inline") do[
                # TODO config for chose_all?, reset?, clear_all?
                # TODO auto focus on input after token entered for reopening select box
                # li('.icon', title: t("admin.concepts.select.chose_all")) do
                #   a '.btn.btn-default.btn-sm.js_select_multi_chose_all', href: '#', data: { id: field_id } do[
                #     i('.icon-ok'),
                #     t("admin.concepts.select.chose_all")
                #   ]end
                # end,
                # li('.icon', title: t("admin.concepts.select.reset")) do
                #   a '.btn.btn-default.btn-sm.js_select_multi_reset', href: '#', data: { id: field_id } do[
                #     i('.icon-undo'),
                #     t("admin.concepts.select.reset")
                #   ]end
                # end,
                # if removable
                #   li '.icon', title: t("admin.concepts.select.clear_all") do
                #     a '.btn.btn-default.btn-sm.js_select_multi_clear_all', href: '#', data: { id: field_id } do[
                #       i('.icon-remove'),
                #       t("admin.concepts.select.clear_all")
                #     ]end
                #   end
                # end,
                if new_params
                  li '.icon', title: wording_for(:link, :new, abstract_model) do
                    a '.btn.btn-default.btn-sm.js_modal_form_new', i('.icon-plus'),
                      data: { js: { params: new_params, select_id: field_id }.to_json },
                      href: '#'
                  end
                end
              ]end,
            )
          end

          def filtering_options
            config = associated_model_config
            abstract_model = config.abstract_model

            selected = selected_objects(abstract_model)
            selected_ids = selected.map{|s| s.send(associated_primary_key)}

            current_action = params[:action].in?(['create', 'new']) ? 'create' : 'update'
            modal = params[:modal].to_b

            if authorized?(:edit, abstract_model) && inline_edit && !modal
              edit_params = { model_name: abstract_model.to_param, modal: true }
            end

            data_js = {
              edit_params: edit_params,
              sortable: !!orderable,
              removable: !!removable,
            }
            if !associated_collection_cache_all
              remote = true
              collection = selected.map{ |o| [o.send(associated_object_label_method), o.send(associated_primary_key)] }
              data_js = data_js.merge!(
                url_params: {
                  model_name: abstract_model.to_param,
                  source_object_id: form.object.id,
                  source_abstract_model: RailsAdmin.config(form.object.class).abstract_model.to_param,
                  associated_collection: name,
                  current_action: current_action,
                  compact: true
                },
                required: required?,
              )
            else
              i = 0
              collection = list_entries(config, :index, associated_collection_scope, false).map do |o|
                [o.send(associated_object_label_method), o.send(associated_primary_key)]
              end.sort_by do |a|
                [selected_ids.index(a[1]) || selected_ids.size, i += 1]
              end
            end

            selected_ids = (hdv = form_default_value).nil? ? selected_ids : hdv

            if authorized?(:new, abstract_model) && inline_add && !modal
              new_params = { model_name: abstract_model.to_param, modal: true }
              new_params.merge!(associations: { inverse_of => (form.object.persisted? ? form.object.id : 'new') }) if inverse_of
            end
            
            [collection, selected_ids, new_params, abstract_model, data_js, remote]
          end

          def selected_objects(abstract_model)
            related_id = params[:associations] && params[:associations][name.to_s]

            if form.object.new_record? && related_id.present? && related_id != 'new'
              [abstract_model.get(related_id)]
            else
              form.object.send(name).presence || form.object.try("cloned_#{name}") || []
            end
          end
        end
      end
    end
  end
end
