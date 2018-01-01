namespace :nginx do
  # TODO healthcheck request
  %w[start stop restart reload].each do |action|
    desc "#{action.capitalize} nginx service"
    task action do
      on release_roles :all do
        execute :sudo, :systemctl, action, 'nginx'
      end
    end
    before "nginx:#{action}", 'nginx:configtest' unless action == 'stop'
  end

  desc "Kill nginx"
  task :kill do
    on release_roles :all do
      execute Sh.kill('nginx', sudo: true)
    end
  end

  desc 'Recover nginx from lost pid'
  task :recover do
    invoke 'nginx:stop'
    invoke 'nginx:kill'
    invoke 'nginx:start'
  end

  desc "Configtest nginx service"
  task :configtest do
    on release_roles :all do
      if test("[ $(sudo service nginx configtest | grep -c 'fail') -eq 0 ]")
        info 'config [OK]'
      else
        abort("nginx configuration is invalid! (Make sure nginx configuration files are readable and correctly formated.)")
      end
    end
  end

  desc 'Export nginx global configuration file'
  task :push do
    on release_roles :all do
      invoke! 'template:push', 'nginx.conf', '/etc/nginx/nginx.conf'
    end
  end

  namespace :app do
    desc 'Enable application (with optional site name)'
    task :enable, [:site] do |t, args|
      on release_roles :all do
        site = args.has_key?(:site) ? args[:site] : fetch(:deploy_dir)
        if test("! [ -h /etc/nginx/sites-enabled/#{site} ]")
          within '/etc/nginx/sites-enabled' do
            site_available = "/etc/nginx/sites-available/#{site}"
            site_enabled = "/etc/nginx/sites-enabled/#{site}"
            execute :sudo, :ln, '-nfs', site_available, site_enabled
          end
        end
      end
    end

    desc 'Disable application (with optional site name)'
    task :disable, [:site] do |t, args|
      on release_roles :all do
        site = args.has_key?(:site) ? args[:site] : fetch(:deploy_dir)
        if test("[ -f /etc/nginx/sites-enabled/#{site} ]")
          within '/etc/nginx/sites-enabled' do
            site_enabled = "/etc/nginx/sites-enabled/#{site}"
            execute :sudo, :rm, '-f', site_enabled
          end
        end
      end
    end

    desc 'Export nginx app configuration file'
    task :push, [:template] do |t, args|
      on release_roles :all do
        template = args[:template].presence || 'nginx_app.conf'
        invoke! 'template:push', template, "/etc/nginx/sites-available/#{fetch(:deploy_dir)}"
      end
    end

    desc 'Remove nginx app configuration file'
    task :remove do
      on release_roles :all do
        if test("[ -f /etc/nginx/sites-available/#{fetch(:deploy_dir)} ]")
          within '/etc/nginx/sites-available' do
            execute :sudo, :rm, fetch(:deploy_dir)
          end
        end
      end
    end

    namespace :maintenance do
      desc "Enable maintenance mode"
      task :enable do
        ENV['MAINTENANCE'] = 'true'
        invoke 'nginx:app:push'
        invoke 'nginx:reload'
      end

      desc "Disable maintenance mode"
      task :disable do
        invoke 'nginx:app:push'
        invoke 'nginx:reload'
      end
    end

    namespace :auth_basic do
      task :add, [:name, :pwd] do |t, args|
        raise "user password cannot be empty" unless (pwd = args[:pwd]).present?
        pwd = `openssl passwd -apr1 "#{pwd}"`.strip
        execute :sudo, Sh.concat('/etc/nginx/.htpasswd', "#{args[:name]}:#{pwd}", unique: true, sh: true)
      end

      task :remove, [:name] do |t, args|
        raise "user name cannot be empty" unless (name = args[:name]).present?
        execute :sudo, Sh.delete_lines!('/etc/nginx/.htpasswd', name)
      end
    end
  end
end
