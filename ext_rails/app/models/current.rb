class Current < ActiveSupport::CurrentAttributes
  attribute :request_id, :session_id
  attribute :locale, :time_zone, :currency
end
