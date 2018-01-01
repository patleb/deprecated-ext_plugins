class User < ApplicationRecord
  jsonb_accessor :data,
    first_name: :string,
    last_name: :string

  alias_attribute :user_id, :id

  def has?(record)
    record.try(:user_id) == id
  end
end
