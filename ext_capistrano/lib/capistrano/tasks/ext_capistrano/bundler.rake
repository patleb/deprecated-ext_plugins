namespace :bundler do
  desc 'Set correct ruby version'
  task :set_correct_ruby_version do
    on release_roles :all do
      within release_path do
        with rails_env: fetch(:stage) do
          if RUBY_VERSION != fetch(:rbenv_ruby)
            execute Sh.sub!("#{release_path}/.ruby-version", RUBY_VERSION, fetch(:rbenv_ruby))
          end
        end
      end
    end
  end
  before 'bundler:install', 'bundler:set_correct_ruby_version'

  desc 'install ext_bundler'
  task :install_ext_bundler do
    on release_roles :all do
      execute Sh.bash <<~CMD
        #{SunCap.rbenv_export}
        #{SunCap.rbenv_init}
        if [[ "$(gem list -i ext_bundler -v #{fetch(:ext_bundler_version)})" == false ]]; then
          gem install ext_bundler -v #{fetch(:ext_bundler_version)}
          gem cleanup ext_bundler
        fi
        if [[ "$(gem list -i gem-path)" == false ]]; then
          gem install gem-path
        fi
        gem path ext_bundler | tr -d "\n" > #{release_path.join('EXT_BUNDLER')}
        echo -n '/lib/ext_bundler.rb' >> #{release_path.join('EXT_BUNDLER')}
      CMD
    end
  end
  before 'bundler:install', 'bundler:install_ext_bundler'
  
  # TODO
  # https://github.com/rudionrails/capistrano-strategy-copy-bundled
  # https://github.com/sonots/capistrano-bundle_rsync
  desc 'Install backup'
  task :install_backup do
    on release_roles(fetch(:backup_roles)) do
      if File.exist?(fetch(:backup_gemfile))
        on fetch(:bundle_servers) do
          within release_path do
            with fetch(:bundle_env_variables, {}) do
              options = []
              options << "--gemfile #{fetch(:backup_gemfile)}"
              options << "--path #{fetch(:bundle_path)}" if fetch(:bundle_path)
              unless test(:bundle, :check, *options)
                options << "--binstubs #{fetch(:bundle_binstubs)}" if fetch(:bundle_binstubs)
                options << "--jobs #{fetch(:bundle_jobs)}" if fetch(:bundle_jobs)
                options << "--without #{fetch(:bundle_without)}" if fetch(:bundle_without)
                options << "#{fetch(:bundle_flags)}" if fetch(:bundle_flags)
                execute :bundle, :install, *options
              end
            end
          end
        end
      end
    end
  end
  after 'bundler:install', 'bundler:install_backup'
end
