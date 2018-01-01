# TODO semaphore
# https://github.com/ClosureTree/with_advisory_lock
# https://hashrocket.com/blog/posts/advisory-locks-in-postgres
# https://vladmihalcea.com/2017/04/12/how-do-postgresql-advisory-locks-work/
# TODO without sleep 5
# https://stackoverflow.com/questions/29954169/automatically-establish-ssh-tunnel-wait-until-ssh-tunnel-is-established-then-e

module ExtRake
  module Openvpn
    extend ActiveSupport::Concern

    class_methods do
      def steps
        [:connect_vpn]
      end

      def vpn_client_name
        SettingsYml[:vpn_client_name] || "client_#{ExtRake.config.rails_env}"
      end
    end

    protected

    def connect_vpn
      sh "sudo systemctl start openvpn@#{self.class.vpn_client_name}"

      sleep 5
    end

    def before_ensure(exception)
      sh "sudo systemctl stop openvpn@#{self.class.vpn_client_name}"
    end
  end
end
