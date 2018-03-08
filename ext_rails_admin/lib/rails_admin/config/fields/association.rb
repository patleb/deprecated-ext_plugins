module RailsAdmin
  module Config
    module Fields
      class Association < RailsAdmin::Config::Fields::Base
        def self.inherited(klass)
          super(klass)
        end

        # Reader for the association information hash
        def association
          @properties
        end

        register_instance_option :pretty_value do
          [value].flatten.select(&:present?).collect do |associated|
            amc = polymorphic? ? RailsAdmin.config(associated) : associated_model_config # perf optimization for non-polymorphic associations
            am = amc.abstract_model
            wording = associated.send(amc.object_label_method)
            can_see = !am.embedded? && (show_action = action(:show, am, associated))
            can_see ? link_to(wording, url_for(action: show_action.action_name, model_name: am.to_param, id: associated.id), class: 'pjax') : ERB::Util.html_escape(wording)
          end.to_sentence.html_safe
        end

        # Accessor whether association is visible or not. By default
        # association checks whether the child model is excluded in
        # configuration or not.
        register_instance_option :visible? do
          @visible ||= !associated_model_config.excluded?
        end

        # use the association name as a key, not the association key anymore!
        register_instance_option :label do
          (@label ||= {})[::I18n.locale] ||= abstract_model.model.human_attribute_name association.name
        end

        # scope for possible associable records
        register_instance_option :associated_collection_scope do
          # bindings[:object] & bindings[:controller] available
          associated_collection_scope_limit = (associated_collection_cache_all ? nil : 30)
          proc do |scope|
            scope.limit(associated_collection_scope_limit)
          end
        end

        # inverse relationship
        register_instance_option :inverse_of do
          association.inverse_of
        end

        # preload entire associated collection (per associated_collection_scope) on load
        # Be sure to set limit in associated_collection_scope if set is large
        register_instance_option :associated_collection_cache_all do
          @associated_collection_cache_all ||= (associated_model_config.abstract_model.count < associated_model_limit)
        end

        # determines whether association's elements can be removed
        register_instance_option :removable? do
          association.foreign_key_nullable?
        end

        register_instance_option :inline_add do
          true
        end

        register_instance_option :inline_edit do
          true
        end

        register_instance_option :eager_load? do
          !!searchable
        end

        register_instance_option :left_joins? do
          false
        end

        register_instance_option :distinct? do
          false
        end

        register_instance_option :render do
          nested_form ? render_nested : render_filtering
        end

        # Reader for the association's child model's configuration
        def associated_model_config
          @associated_model_config ||= RailsAdmin.config(association.klass)
        end

        # Reader for the association's child model object's label method
        def associated_object_label_method
          @associated_object_label_method ||= associated_model_config.object_label_method
        end

        # Reader for associated primary key
        def associated_primary_key
          @associated_primary_key ||= association.primary_key
        end

        # Reader for the association's key
        def foreign_key
          association.foreign_key
        end

        # Reader whether this is a polymorphic association
        def polymorphic?
          association.polymorphic?
        end

        # Reader for nested attributes
        register_instance_option :nested_form do
          association.nested_options
        end

        # Reader for the association's value unformatted
        def value
          bindings[:object].send(association.name)
        end

        # has many?
        def multiple?
          true
        end

        def virtual?
          true
        end

        def associated_model_limit
          RailsAdmin.config.default_associated_collection_limit
        end

        def render_nested
          config = associated_model_config
          abstract_model = config.abstract_model
          selected = selected_object(abstract_model) || form.object.send(name)
          can_create, can_destroy = !nested_form[:update_only], nested_form[:allow_destroy]
          with_errors = !!selected && selected.errors.any?
          opened = active? || with_errors
          association_id = form.nested_form_dom_id(name)

          div '.js_nested_form_wrapper' do[
            div('.controls.col-sm-10') do[
              div('.btn-group') do[
                a(".btn.btn-#{with_errors ? 'danger' : 'info'}.js_nested_form_toggle#{'.js_nested_form_last_button' if selected}#{'.active' if opened}#{'.js_disabled' unless selected}", href: '#') do
                  i ".icon-white.#{opened ? 'icon-chevron-down' : 'icon-chevron-right'}"
                end,
                if can_create && inline_add
                  form.link_to_add name, class: 'btn btn-info js_nested_form_one', style: ('display:none' if selected) do
                    html(
                      i('.icon-plus.icon-white'),
                      wording_for(:link, :new, associated_model_config.abstract_model)
                    )
                  end
                end,
              ]end,
              form.errors_for(self),
              form.help_for(self),
              ul(".nav.nav-tabs.hidden") do
                if selected
                  li class: [('active' if with_errors), ('has-error' if with_errors)].compact do
                    a href: "#tab_#{association_id}_0", data: { toggle: 'tab' } do
                      selected.send(associated_object_label_method)
                    end
                  end
                end
              end,
            ]end,
            div('.tab-content', style: ('display:none' unless opened)) do
              if selected.nil?
                template_object = m.send("build_#{name}")
                form.fields_for name, template_object do |f|
                  html(
                    f.link_to_remove(name) do
                      f.span ".btn.btn-sm.btn-default", f.i('.icon-trash')
                    end,
                    f.generate(action: :nested, model_config: associated_model_config, nested_in: self)
                  )
                end
              end
              if selected
                div "#tab_#{association_id}_0.tab-pane.fade#{'.active.in' if with_errors}" do
                  form.fields_for name, selected do |f|
                    is_template = f.options[:nested_form_template] || selected.new_record?
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
          collection, selected_id, new_params, edit_params, abstract_model, data_js, remote = filtering_options
          field_id = form.dom_id(self)
          html(
            div(class: bs_form_row) do
              form.select(method_name, collection, { include_blank: true, selected: selected_id },
                html_attributes.reverse_merge(
                  class: "#{'js_field_input js_select_remote' if remote} #{'js_modal_form_editable' if edit_params} form-control",
                  data: { js: data_js.to_json }
                )
              )
            end,
            ul(".list-inline") do[
              if new_params
                li '.icon', title: wording_for(:link, :new, abstract_model) do
                  a ".btn.btn-default.btn-sm.js_modal_form_new", i('.icon-plus'),
                    data: { js: { params: new_params, select_id: field_id }.to_json },
                    href: '#'
                end
              end,
              if edit_params
                li '.icon', title: wording_for(:link, :edit, abstract_model) do
                  a ".btn.btn-default.btn-sm.js_modal_form_edit", i('.icon-pencil'),
                    data: { js: { params: edit_params, select_id: field_id }.to_json },
                    href: '#',
                    id: "js_modal_form_editable_#{field_id}",
                    class: ('disabled' unless value)
                end
              end
            ]end
          )
        end
        
        def filtering_options
          config = associated_model_config
          abstract_model = config.abstract_model

          if (selected = selected_object(abstract_model))
            selected_id = selected.send(associated_primary_key)
            selected_name = selected.send(associated_object_label_method)
          else
            selected_id = self.selected_id
            selected_name = formatted_value
          end

          current_action = params[:action].in?(['create', 'new']) ? 'create' : 'update'
          modal = params[:modal].to_b

          if authorized?(:edit, abstract_model) && inline_edit && !modal
            edit_params = { model_name: abstract_model.to_param, modal: true }
          end

          if !associated_collection_cache_all
            remote = true
            collection = [[selected_name, selected_id]]
            data_js = {
              url_params: {
                model_name: abstract_model.to_param,
                source_object_id: form.object.id,
                source_abstract_model: RailsAdmin.config(form.object.class).abstract_model.to_param,
                associated_collection: name,
                current_action: current_action,
                compact: true
              },
              required: required?,
            }
          else
            collection = list_entries(config, :index, associated_collection_scope, false).map do |o|
              [o.send(associated_object_label_method), o.send(associated_primary_key)]
            end
          end

          selected_id = (hdv = form_default_value).nil? ? selected_id : hdv

          if !form.object.new_record? && authorized?(:new, abstract_model) && inline_add && !modal
            new_params = { model_name: abstract_model.to_param, modal: true }
            new_params.merge!(associations: { inverse_of => (form.object.persisted? ? form.object.id : 'new') }) if inverse_of
          end

          [collection, selected_id, new_params, edit_params, abstract_model, data_js, remote]
        end

        def selected_object(abstract_model)
          related_id = params[:associations] && params[:associations][name.to_s]

          if form.object.new_record? && related_id.present? && related_id != 'new'
            abstract_model.get(related_id)
          end
        end
      end
    end
  end
end
