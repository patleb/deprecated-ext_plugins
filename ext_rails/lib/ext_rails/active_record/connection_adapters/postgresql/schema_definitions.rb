module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module SchemaDefinitions
        def interval(name, options = {})
          column(name, :interval, options)
        end
      end
    end
  end
end
