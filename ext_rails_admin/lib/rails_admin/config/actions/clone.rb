module RailsAdmin
  module Config
    module Actions
      class Clone < RailsAdmin::Config::Actions::Base
        register_instance_option :member do
          true
        end

        register_instance_option :http_methods do
          [:get]
        end

        register_instance_option :link_icon do
          'fa fa-clone'
        end
      end
    end
  end
end
