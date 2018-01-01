namespace :vpn do
  namespace :client do
    desc 'generate client .ovpn key'
    task :create, [:name, :path, :linux] do |t, args|
      on release_roles :all do
        options = { name: args[:name], linux: (args[:linux] == 'linux' || args[:linux].to_b), print: false }
        execute Sh.bash(SunCap.create_client_ovpn(options), sudo: true)
        invoke! 'files:download', "/opt/openvpn_data/clients/keys/#{args[:name]}.ovpn", Pathname.new(args[:path] || '').to_s
      end
    end

    desc 'revoke client .ovpn key'
    task :revoke, [:name] do |t, args|
      on release_roles :all do
        execute Sh.bash(SunCap.revoke_client_ovpn(name: args[:name]), sudo: true)
      end
    end
  end

  namespace :server do
    %w[start stop restart].each do |action|
      desc "#{action.capitalize} openvpn service"
      task action do
        on release_roles :all do
          execute :sudo, :systemctl, action, 'openvpn@server'
        end
      end
    end
  end
end
