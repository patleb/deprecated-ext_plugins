module RailsAdmin
  module Config
    module Actions
      class Chart < RailsAdmin::Config::Actions::Base
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :link_icon do
          'fa fa-bar-chart'
        end

        register_instance_option :filter_box? do
          true
        end
      end
    end
  end
end
