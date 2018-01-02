class Flash < ExtAsync.config.parent_model.constantize
  SESSION_ID = /[\da-f]{32}/
  REQUEST_ID = /[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}/

  validates :id, format: { with: /\A#{SESSION_ID}:#{REQUEST_ID}\z/ }
  validates :messages, presence: true

  def self.[]=(type, message)
    Current.flash ||= new(id: "#{Current.session_id}:#{Current.request_id}")
    Current.flash.messages[type] = message
  end

  def self.cleanup
    expires_at = ExtAsync.config.flash_expires_in.ago
    where.has{ updated_at < expires_at }.delete_all
  end
end
