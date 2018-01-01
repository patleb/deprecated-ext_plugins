module RailsAdmin
  module Config
    module Actions
      class New < RailsAdmin::Config::Actions::Base
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post] # NEW / CREATE
        end

        register_instance_option :link_icon do
          'icon-plus'
        end
      end
    end
  end
end
