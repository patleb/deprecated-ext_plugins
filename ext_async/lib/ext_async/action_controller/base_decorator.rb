ActionController::Base.class_eval do
  after_action :later_request!

  protected

  def later_request!
    return unless Current.later

    later = (session[:later] ||= [])
    later.shift if later.size >= 10
    later << Current.request_id
  end
end
