module RailsAdmin
  module Config
    module Actions
      class BulkDelete < RailsAdmin::Config::Actions::Base
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:post, :delete]
        end

        register_instance_option :authorization_key do
          :destroy
        end

        register_instance_option :bulkable? do
          true
        end
      end
    end
  end
end
