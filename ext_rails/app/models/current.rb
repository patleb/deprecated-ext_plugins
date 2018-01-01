class Current < ActiveSupport::CurrentAttributes
  attribute :request_id
  attribute :locale, :time_zone, :currency
end
