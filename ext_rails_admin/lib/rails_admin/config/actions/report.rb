module RailsAdmin
  module Config
    module Actions
      class Report < RailsAdmin::Config::Actions::Base
        register_instance_option :member do
          true
        end

        register_instance_option :http_methods do
          [:get]
        end

        register_instance_option :link_icon do
          'fa fa-file-pdf-o'
        end

        register_instance_option :nav_tab? do
          false
        end
      end
    end
  end
end
