module RailsAdmin
  module Config
    module Actions
      class Base
        include RailsAdmin::Config::Proxyable
        include RailsAdmin::Config::Configurable
        include RailsAdmin::Config::Hideable

        register_instance_option :only do
          nil
        end

        register_instance_option :except do
          []
        end

        # http://getbootstrap.com/2.3.2/base-css.html#icons
        register_instance_option :link_icon do
          'icon-question-sign'
        end

        # Should the action be visible
        register_instance_option :visible? do
          authorized?
        end

        register_instance_option :enabled? do
          bindings[:abstract_model].nil? || (
            (only.nil? || [only].flatten.collect(&:to_s).include?(bindings[:abstract_model].to_s)) &&
            ![except].flatten.collect(&:to_s).include?(bindings[:abstract_model].to_s) &&
            !bindings[:abstract_model].config.excluded?
          )
        end

        register_instance_option :authorized? do
          if enabled?
            if bindings[:controller].try(:authorization_adapter).nil?
              true
            elsif bindings[:controller].authorization_adapter.authorized?(authorization_key, bindings[:abstract_model], bindings[:object])
              true
            else
              false
            end
          else
            false
          end
        end

        # Is the action acting on the root level (Example: /admin/contact)
        register_instance_option :root? do
          false
        end

        # Is the action on a model scope (Example: /admin/team/export)
        register_instance_option :collection? do
          false
        end

        # Is the action on an object scope (Example: /admin/team/1/edit)
        register_instance_option :member? do
          false
        end

        # Render via pjax?
        register_instance_option :pjax? do
          true
        end

        # Model scoped actions only. You will need to handle params[:bulk_ids] in controller
        register_instance_option :bulkable? do
          false
        end

        # View partial name (called in default :controller block)
        register_instance_option :template_name do
          key.to_sym
        end

        # For Cancan and the like
        register_instance_option :authorization_key do
          key.to_sym
        end

        # List of methods allowed. Note that you are responsible for correctly handling them in :controller block
        register_instance_option :http_methods do
          [:get]
        end

        # Url fragment
        register_instance_option :route_fragment do
          custom_key.to_s
        end

        # Controller action name
        register_instance_option :action_name do
          custom_key.to_sym
        end

        # I18n key
        register_instance_option :i18n_key do
          key
        end

        # User should override only custom_key (action name and route fragment change, allows for duplicate actions)
        register_instance_option :custom_key do
          key
        end

        register_instance_option :nav_tab? do
          true
        end

        register_instance_option :filter_box? do
          false
        end

        # Off API.

        def key
          self.class.key
        end

        def self.key
          name.to_s.demodulize.underscore.to_sym
        end
      end
    end
  end
end
