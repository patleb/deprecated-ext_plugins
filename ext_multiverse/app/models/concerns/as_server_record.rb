module AsServerRecord
  extend ActiveSupport::Concern

  included do
    class << self
      delegate_to ServerRecord,
        :connection_handler,
        :connection_specification_name,
        :remove_connection
    end
  end
end
