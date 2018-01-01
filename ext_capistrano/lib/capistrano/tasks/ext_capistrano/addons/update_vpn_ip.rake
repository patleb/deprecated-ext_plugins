# config/schedule.rb
#
# every :minute do
#   bash 'update_vpn_ip.sh'
# end

namespace :update_vpn_ip do
  desc 'push update_vpn_ip.sh'
  task :push do
    on release_roles fetch(:whenever_roles) do
      invoke! 'template:push', 'addons/update_vpn_ip.sh', release_path.join('bin', 'update_vpn_ip.sh')
    end
  end
  # after 'git:create_release', 'update_vpn_ip:push'
end
