module ExtAsync
  class ForbiddenRemoteIp < ::StandardError
  end

  module AsLocalRequest
    extend ActiveSupport::Concern

    included do
      before_action :local_request!
    end

    def with_session?
      false
    end

    private

    def local_request!
      # TODO use nginx allow/deny
      unless ExtAsync.config.allowed_ips.include? request.remote_ip
        exception = ForbiddenRemoteIp.new "[#{request.remote_ip}]"
        log exception, subject: :forbidden
        head :forbidden
      end
    end
  end
end
