class Current < ActiveSupport::CurrentAttributes
  attribute :session_id, :request_id
  attribute :locale, :time_zone, :currency
end
