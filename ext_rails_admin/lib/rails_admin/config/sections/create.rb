module RailsAdmin
  module Config
    module Sections
      # Configuration of the edit view for a new object
      class Create < RailsAdmin::Config::Sections::Edit
        register_instance_option :inline_create? do
          false
        end
      end
    end
  end
end
