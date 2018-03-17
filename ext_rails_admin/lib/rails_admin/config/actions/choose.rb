module RailsAdmin
  module Config
    module Actions
      class Choose < RailsAdmin::Config::Actions::Base
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:post, :delete]
        end
      end
    end
  end
end
