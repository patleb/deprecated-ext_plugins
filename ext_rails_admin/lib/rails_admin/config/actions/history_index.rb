module RailsAdmin
  module Config
    module Actions
      class HistoryIndex < RailsAdmin::Config::Actions::Base
        register_instance_option :authorization_key do
          :history
        end

        register_instance_option :collection do
          true
        end

        register_instance_option :route_fragment do
          'history'
        end

        register_instance_option :template_name do
          :history
        end

        register_instance_option :link_icon do
          'icon-book'
        end
      end
    end
  end
end
