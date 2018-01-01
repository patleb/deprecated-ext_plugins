module RailsAdmin
  module Config
    module Fields
      module Types
        class Citext < RailsAdmin::Config::Fields::Types::String
          RailsAdmin::Config::Fields::Types::register(self)
        end
      end
    end
  end

  # Allow for searching/filtering of `citext` fields.
  module Adapters
    module ActiveRecord
      module CitextStatement
        private

        def build_statement_for_type
          if @type == :citext
            build_statement_for_string
          else
            super
          end
        end
      end

      class StatementBuilder < RailsAdmin::AbstractModel::StatementBuilder
        prepend CitextStatement
      end
    end
  end
end
