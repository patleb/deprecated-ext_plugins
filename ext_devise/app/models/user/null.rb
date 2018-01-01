class User::Null < ActiveType::Object
  attribute :id
  attribute :first_name
  attribute :last_name

  alias_attribute :user_id, :id

  def has?(_record)
    false
  end
end
