class Flash < ExtAsync.config.parent_model.constantize
  validates :session_id, format: { with: /\A[\da-f]{32}\z/ }
  validates :request_id, format: { with: /\A[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}\z/ }
  validates :messages, presence: true

  def self.[](type)
    flash.messages[type]
  end

  def self.[]=(type, message)
    flash.messages[type] = message
  end

  def self.cleanup
    expires_at = ExtAsync.config.flash_expires_in.ago
    where.has{ updated_at < expires_at }.delete_all
  end

  private_class_method

  def self.flash
    Current.flash ||= new(session_id: Current.session_id, request_id: Current.request_id)
  end
end
