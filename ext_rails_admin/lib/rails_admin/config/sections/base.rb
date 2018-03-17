module RailsAdmin
  module Config
    module Sections
      # Configuration of the show view for a new object
      class Base
        include RailsAdmin::Config::Proxyable
        include RailsAdmin::Config::Configurable
        include RailsAdmin::Config::Inspectable

        include RailsAdmin::Config::HasFields
        include RailsAdmin::Config::HasGroups
        include RailsAdmin::Config::HasDescription

        attr_reader :abstract_model
        attr_reader :parent, :root

        NAMED_INSTANCE_VARIABLES = [:@parent, :@root, :@abstract_model].freeze

        def initialize(parent)
          @parent = parent
          @root = parent.root

          @abstract_model = root.abstract_model
        end

        # TODO show time zone in list view if specified
        register_instance_option :time_zone do
          nil
        end

        register_instance_option :choose? do
          false
        end
      end
    end
  end
end
