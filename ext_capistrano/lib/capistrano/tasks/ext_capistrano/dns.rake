namespace :dns do
  namespace :hosts do
    desc 'push /etc/hosts defined by :dns_hosts'
    task :push do
      on release_roles :all do
        execute Sh.bash(SunCap.build_hosts(fetch(:admin_name), fetch(:server)), sudo: true)
      end
    end
  end

  %w[start stop restart reload].each do |action|
    desc "#{action.capitalize} dnsmasq service"
    task action do
      on release_roles :all do
        execute :sudo, :systemctl, action, 'dnsmasq'
      end
    end
  end
end
