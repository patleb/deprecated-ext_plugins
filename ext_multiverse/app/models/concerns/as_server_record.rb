module AsServerRecord
  extend ActiveSupport::Concern

  included do
    class << self
      delegate_to ServerRecord,
        :connection_pool,
        :retrieve_connection,
        :connected?,
        :remove_connection,
        :clear_active_connections!,
        :clear_reloadable_connections!,
        :clear_all_connections!
    end
  end
end
