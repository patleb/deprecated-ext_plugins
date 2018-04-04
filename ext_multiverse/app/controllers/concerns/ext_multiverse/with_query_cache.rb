module ExtMultiverse
  module WithQueryCache
    extend ActiveSupport::Concern

    included do
      around_action :with_query_cache
    end

    def with_query_cache
      ServerRecord.connection.cache{ yield }
    end
  end
end
