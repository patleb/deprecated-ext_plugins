require 'rails_admin/support/i18n'

module RailsAdmin
  module ApplicationHelper
    include RailsAdmin::Support::I18n

    def capitalize_first_letter(wording)
      return nil unless wording.present? && wording.is_a?(String)

      wording = wording.dup
      wording[0].capitalize!
      wording
    end

    def authorized?(action_name, abstract_model = nil, object = nil)
      object = nil if object.try :new_record?
      action(action_name, abstract_model, object).try(:authorized?)
    end

    def current_action?(action, abstract_model = @abstract_model, object = @object)
      @action.custom_key == action.custom_key &&
        abstract_model.try(:to_param) == @abstract_model.try(:to_param) &&
        (@object.try(:persisted?) ? @object.id == object.try(:id) : !object.try(:persisted?))
    end

    def action(key, abstract_model = nil, object = nil)
      RailsAdmin::Config::Actions.find(key, controller: controller, abstract_model: abstract_model, object: object)
    end

    def actions(scope = :all, abstract_model = nil, object = nil)
      RailsAdmin::Config::Actions.all(scope, controller: controller, abstract_model: abstract_model, object: object)
    end

    def edit_user_link
      return nil unless current_user.respond_to?(:email)
      return nil unless abstract_model = RailsAdmin.config(current_user.class).abstract_model
      return nil unless (edit_action = RailsAdmin::Config::Actions.find(:edit, controller: controller, abstract_model: abstract_model, object: current_user)).try(:authorized?)
      link_to rails_admin.url_for(action: edit_action.action_name, model_name: abstract_model.to_param, id: current_user.id, controller: 'rails_admin/main'), class: 'pjax' do
        html = []
        html << image_tag("#{(request.ssl? ? 'https://secure' : 'http://www')}.gravatar.com/avatar/#{Digest::MD5.hexdigest current_user.email}?s=30", alt: '') if RailsAdmin::Config.show_gravatar && current_user.email.present?
        html << content_tag(:span, current_user.email)
        html.join.html_safe
      end
    end

    def logout_path
      if defined?(Devise)
        scope = Devise::Mapping.find_scope!(current_user)
        main_app.send("destroy_#{scope}_session_path") rescue false
      elsif main_app.respond_to?(:logout_path)
        main_app.logout_path
      end
    end

    def logout_method
      return [Devise.sign_out_via].flatten.first if defined?(Devise)
      :delete
    end

    def wording_for(label, action = @action, abstract_model = @abstract_model, object = @object)
      model_config = abstract_model.try(:config)
      object = abstract_model && object.is_a?(abstract_model.model) ? object : nil
      action = RailsAdmin::Config::Actions.find(action.to_sym) if action.is_a?(Symbol) || action.is_a?(String)

      capitalize_first_letter I18n.t(
        "admin.actions.#{action.i18n_key}.#{label}",
        model_label: model_config && model_config.label,
        model_label_plural: model_config && model_config.label_plural,
        object_label: model_config && object.try(model_config.object_label_method),
      )
    end

    def main_navigation
      nodes_stack = RailsAdmin::Config.visible_models(controller: controller)
      node_model_names = nodes_stack.collect { |c| c.abstract_model.model_name }

      nodes_stack.group_by(&:navigation_label).collect do |navigation_label, nodes|
        nodes = nodes.select { |n| n.parent.nil? || !n.parent.to_s.in?(node_model_names) }
        li_stack = navigation nodes_stack, nodes

        label = navigation_label || t('admin.misc.navigation')

        %(<li class='dropdown-header'>#{capitalize_first_letter label}</li>#{li_stack}) if li_stack.present?
      end.join.html_safe
    end

    def static_navigation
      li_stack = RailsAdmin::Config.navigation_static_links.collect do |title, url|
        content_tag(:li, link_to(title.to_s, url, target: '_blank'))
      end.join

      label = RailsAdmin::Config.navigation_static_label || t('admin.misc.navigation_static_label')
      li_stack = %(<li class='dropdown-header'>#{label}</li>#{li_stack}).html_safe if li_stack.present?
      li_stack
    end

    def navigation(nodes_stack, nodes, level = 0)
      nodes.collect do |node|
        model_param = node.abstract_model.to_param
        url         = rails_admin.url_for(action: :index, controller: 'rails_admin/main', model_name: model_param)
        level_class = " nav-level-#{level}" if level > 0
        nav_icon = node.navigation_icon ? %(<i class="#{node.navigation_icon}"></i>).html_safe : ''
        li = content_tag :li, data: {model: model_param} do
          link_to nav_icon + capitalize_first_letter(node.label_plural), url, class: "pjax#{level_class}"
        end
        li + navigation(nodes_stack, nodes_stack.select { |n| n.parent.to_s == node.abstract_model.model_name }, level + 1)
      end.join.html_safe
    end

    # parent => :root, :collection, :member
    def menu_for(parent, abstract_model = nil, object = nil, only_icon = false)
      actions = actions(parent, abstract_model, object).select do |action|
        action.http_methods.include?(:get) && action.nav_tab?
      end
      list_inline = parent == :member && only_icon
      actions.map do |action|
        inline_create, filter_box = false, false
        url = if action.action_name == :new && @model_config.create.inline_create?
          inline_create = true
          '#'
        else
          path_params = {action: action.action_name, controller: 'rails_admin/main', model_name: abstract_model.try(:to_param), id: (object.try(:persisted?) && object.try(:id) || nil)}
          if action.filter_box?
            filter_box = true
            path_params[:scope] = params[:scope]
          end
          rails_admin.url_for(path_params)
        end
        wording = wording_for(:menu, action)
        li_classes = ["icon #{action.key}_#{parent}_link"]
        li_classes << ' active' if current_action?(action)
        li_classes << ' js_inline_create_link' if inline_create
        li_classes << ' js_filter_box_link' if filter_box
        %(
          <li title="#{wording if only_icon}" class="#{li_classes.join}">
            <a class="#{'btn btn-default btn-xs' if list_inline} #{'pjax' if action.pjax?}" href="#{url}">
              <i class="#{action.link_icon}"></i>
              #{"<span>#{wording}</span>" unless only_icon}
            </a>
          </li>
        )
      end.join.html_safe
    end

    def bulk_menu
      return '' unless bulk_menu?
      content_tag :li, class: 'bulk_actions dropdown pull-right' do
        content_tag(:a, class: 'dropdown-toggle', data: {toggle: 'dropdown'}, href: '#') { t('admin.misc.bulk_menu_title').html_safe + ' ' + '<b class="caret"></b>'.html_safe } +
          content_tag(:ul, class: 'dropdown-menu position_right') do
            bulkables.map do |action|
              content_tag :li, class: "bulk_#{action.action_name}" do
                link_to wording_for(:bulk_link, action), '#', class: 'js_application_bulk_action', data: {action: action.action_name}
              end
            end.join.html_safe
          end
      end.html_safe
    end

    def bulk_menu?
      bulkables.any?
    end

    def bulkables
      @_bulkables ||= actions(:bulkable, @abstract_model)
    end
  end
end
