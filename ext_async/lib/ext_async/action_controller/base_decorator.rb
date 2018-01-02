ActionController::Base.class_eval do
  before_action :with_flashes!
  after_action :later_request!

  protected

  def with_flashes!
    return if respond_to?(:local_request!) || session[:later].blank?

    ids = Flash.where(session_id: session.id, request_id: session[:later]).pluck(:id, :messages).map do |id, messages|
      messages.each do |type, message|
        flash.now[type] = message
      end
      id
    end

    if ids.any?
      session[:later].clear
      Flash.where(id: ids).delete_all
    end
  end

  def later_request!
    return unless Current.later

    later = (session[:later] ||= [])
    later.shift if later.size >= ExtAsync.config.max_flashes
    later << Current.request_id
  end
end
