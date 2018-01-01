module RailsAdmin
  class FormBuilder < ::ActionView::Helpers::FormBuilder
    include RailsAdmin::ApplicationHelper

    def generate(options = {})
      without_field_error_proc_added_div do
        options.reverse_merge!(
          action: params[:action],
          model_config: model_config,
          nested_in: false,
        )

        html(
          visible_groups(options[:model_config], generator_action(options[:action], options[:nested_in])).map do |fieldset|
            fieldset_for fieldset, options[:nested_in]
          end,
          (options[:nested_in] ? '' : render(partial: 'rails_admin/main/submit_buttons'))
        )
      end
    end

    def fieldset_for(fieldset, nested_in)
      bindings = {
        form: self,
        object: @object,
        view: @template,
        controller: controller,
      }
      return if (fields = fieldset.with(bindings).visible_fields).empty?

      if nested_in
        nested_in.bindings = bindings if nested_in.bindings.nil?
      end

      fieldset do[
        legend(class: fieldset.name == :default ? 'hidden' : '') do[
          i(".icon-chevron-#{(fieldset.active? ? 'down' : 'right')}"),
          "\n#{fieldset.label}"
        ]end,
        if fieldset.help.present?
          p_(fieldset.help)
        end,
        fields.map{ |field| field_wrapper_for(field, nested_in) }
      ]end
    end

    def field_wrapper_for(field, nested_in)
      if field.label
        # do not show nested field if the target is the origin
        unless nested_field_association?(field, nested_in)
          css = "form-group control-group #{field.type_css_class} #{field.css_class} #{'error' if field.errors.present?}"
          div(class: css, id: "#{dom_id(field)}_field") do[
            label(field.method_name, capitalize_first_letter(field.label), class: 'col-sm-2 control-label'),
            (field.nested_form ? field_for(field) : input_for(field))
          ]end
        end
      else
        field.nested_form ? field_for(field) : input_for(field)
      end
    end

    def input_for(field)
      css = "#{'col-sm-10 controls' unless field.type == :hidden} #{'has-error' if field.errors.present?}"
      div(class: css) do
        field_for(field) + errors_for(field) + help_for(field)
      end
    end

    def errors_for(field)
      field.errors.present? ? span('.help-inline.text-danger', field.errors.to_sentence) : ''.html_safe
    end

    def help_for(field)
      field.help.present? ? span('.help-block', field.help) : ''.html_safe
    end

    def field_for(field)
      field.read_only? ? div('.form-control-static', field.pretty_value) : field.render
    end

    def object_label
      model_config = RailsAdmin.config(object)
      model_label = model_config.label
      if object.new_record?
        I18n.t('admin.form.new_model', name: model_label)
      else
        object.send(model_config.object_label_method).presence || "#{model_config.label} ##{object.id}"
      end
    end

    def dom_id(field)
      (@dom_id ||= {})[field.name] ||= [
        @object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, ''),
        options[:index],
        field.method_name,
      ].reject(&:blank?).join('_')
    end

    def dom_name(field)
      (@dom_name ||= {})[field.name] ||= %(#{@object_name}#{options[:index] && "[#{options[:index]}]"}[#{field.method_name}]#{field.is_a?(Config::Fields::Association) && field.multiple? ? '[]' : ''})
    end

    def link_to_add(text, association = nil, html_options = nil, &block)
      html_options, association, text = association, text, capture(&block) if block_given?

      unless object.respond_to?("#{association}_attributes=")
        raise ArgumentError, "Invalid association. Make sure that accepts_nested_attributes_for is used for #{association.inspect} association."
      end

      html_options ||= {}
      association_id = nested_form_dom_id(association)
      html_options.symbolize_keys!
      html_options[:class] ||= []
      html_options[:class] << " js_nested_form_add"
      html_options[:data] ||= {}
      html_options[:data][:js] = { association_id: association_id }.to_json
      html_options[:href] ||= '#'
      model_object = object.class.reflect_on_association(association).klass.new

      after_nested_form(association_id) do
        block, options = @nested_form_fields[association_id].values_at(:block, :options)
        options[:child_index] = "js_nested_form_child_#{association_id}"
        options[:nested_form_template] = true
        template = fields_for(association, model_object, options, &block)
        object_label = RailsAdmin.config(model_object).label
        div '.js_base_template',
          id: "js_nested_form_template_#{association_id}",
          data: { js: { template: template, object_label: I18n.t('admin.form.new_model', name: object_label) }.to_json }
      end
      link_to(text, nil, html_options)
    end

    def link_to_remove(text, association = nil, html_options = nil, &block)
      html_options, association, text = association, text, capture(&block) if block_given?

      html_options ||= {}
      html_options[:class] ||= []
      html_options[:class] << " js_nested_form_remove"
      html_options[:data] ||= {}
      html_options[:data][:js] = { association_id: nested_form_dom_id(association) }.to_json
      html_options[:href] ||= '#'

      hidden_field(:_destroy) << link_to(text, nil, html_options)
    end

    def nested_form_dom_id(association)
      (@nested_form_dom_id ||= {})[association] ||= begin
        assocs = object_name.to_s.scan(/(\w+)_attributes/).map(&:first)
        assocs << association
        assocs.join('_')
      end
    end

    def model_config
      @template.instance_variable_get(:@model_config)
    end

    def method_missing(name, *args, &block)
      @template.__send__(name, *args, &block)
    end

    def respond_to_missing?(name, include_private = false)
      @template.respond_to?(name, include_private) || super
    end

    protected

    def generator_action(action, nested)
      if nested
        action = :nested
      elsif request.format == 'text/javascript'
        action = :modal
      end

      action
    end

    def visible_groups(model_config, action)
      model_config.send(action).with(
        form: self,
        object: @object,
        view: @template,
        controller: controller,
      ).visible_groups
    end

    def without_field_error_proc_added_div
      default_field_error_proc = ::ActionView::Base.field_error_proc
      begin
        ::ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
        yield
      ensure
        ::ActionView::Base.field_error_proc = default_field_error_proc
      end
    end

    private

    def nested_field_association?(field, nested_in)
      field.inverse_of.presence && nested_in.presence && field.inverse_of == nested_in.name &&
        (model_config.abstract_model == field.abstract_model || field.name == nested_in.inverse_of)
    end

    def fields_for_with_nested_attributes(association_name, association, options, block)
      @nested_form_fields ||= {}
      @nested_form_fields[nested_form_dom_id(association_name)] = { block: block, options: options }

      super(association_name, association, options, block)
    end
  end
end
