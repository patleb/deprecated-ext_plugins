ActionController::Base.class_eval do
  module WithFlashes
    def render(*args)
      return super unless with_session? && session[:later].present?

      ids = Flash.where(session_id: session.id, request_id: session[:later]).pluck(:id, :messages).map do |id, messages|
        messages.each do |type, message|
          flash.now[type] ||= ''
          flash.now[type] += message
        end
        id
      end

      if ids.any?
        session[:later].clear
        Flash.where(id: ids).delete_all
      end

      super
    end
  end
  prepend WithFlashes

  after_action :later_request!

  protected

  def later_request!
    return unless Current.later

    later = (session[:later] ||= [])
    later.shift if later.size >= ExtAsync.config.max_flashes
    later << Current.request_id
  end
end
