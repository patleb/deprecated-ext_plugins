module RailsAdmin
  module Config
    module Sections
      # Configuration of the list view
      class List < RailsAdmin::Config::Sections::Base
        register_instance_option :filters do
          []
        end

        register_instance_option :query? do
          true
        end

        # Number of items listed per page
        register_instance_option :items_per_page do
          RailsAdmin::Config.default_items_per_page
        end

        register_instance_option :sort_by do
          parent.abstract_model.primary_key
        end

        register_instance_option :sort_reverse? do
          true # By default show latest first
        end

        register_instance_option :from_first? do
          true # Paginate from the first item of the first request before loading more items
        end

        register_instance_option :scopes do
          []
        end

        register_instance_option :include_columns do
          nil
        end

        register_instance_option :exclude_columns do
          nil
        end

        register_instance_option :freeze_columns do
          nil # TODO first columns (0, 1, 2) --> 0 is bulk actions
        end

        register_instance_option :total_count do
          nil
        end

        register_instance_option :exists? do
          true
        end

        def no_filters?
          if !(list = bindings[:list])
            true
          elsif (values = list.values).has_key? :where
            values[:where].send(:predicates).size <= 1
          else
            true
          end
        end
      end
    end
  end
end
