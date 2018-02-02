# https://github.com/capistrano/sshkit/blob/master/EXAMPLES.md
include ExtCapistrano::FileHelper
include ExtCapistrano::UrlHelper

namespace :load do
  task :defaults do
    set :single_server,       -> { true }
    set :admin_name,          -> { fetch(:stage).to_s == 'vagrant' ? 'vagrant' : 'ubuntu' }
    set :deploy_dir,          -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :deploy_to,           -> { "/home/deployer/#{fetch(:deploy_dir)}" }
    set :precompile_local,    -> { false }
    set :backup_gemfile,      -> { 'Backupfile' }
    set :app_root,            -> { ENV['RAILS_ROOT'] || '' } # -> { "../#{fetch(:application)}" }
    set :docker_dir,          -> { 'docker' }
    set :migration_role,      -> { :web }
    set :assets_roles,        -> { :web }
    set :whenever_roles,      -> { :web }
    set :backup_roles,        -> { :web }
    set :db_roles,            -> { :web }

    set :pty,                 -> { true }

    set :files_public_dirs,   -> { %w(system images) }
    set :files_private_dirs,  -> { [] }

    set :rbenv_ruby,          -> { RUBY_VERSION }
    set :rbenv_prefix,        -> { "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec" }

    set :ext_bundler_version, -> { '2.0.10' }
    
    set :secrets_excluded,    -> { %w(
      aws_access_key_id
      aws_secret_access_key
      git_public_key_id
      admin_private_key
    ) }

    set :nginx_max_body_size, -> { '10m' }
    set :nginx_public_dirs,   -> { fetch(:files_public_dirs) }
    set :nginx_public_files,  -> { %w(
      404.html
      408.html
      422.html
      500.html
      503.html
      apple-touch-icon.png
      apple-touch-icon-precomposed.png
      favicon.ico
      robots.txt
    ) }
    set :nginx_domain,        -> { fetch(:server).split('.').last(2).join('.') }
    set :nginx_satisfy,       -> { false }
    set :nginx_denied_ips,    -> { [] }
    set :nginx_allowed_ips,   -> { [] }
    set :nginx_auth_basic,    -> { false }
    set :nginx_redirects,     -> { {} }
    set :nginx_upstreams,     -> { {} }
    set :nginx_locations,     -> { {} }
    set :nginx_rails,         -> { true }
    set :nginx_deferred,      -> { fetch(:nginx_rails) && fetch(:stage) == :production }

    set :passenger_restart_command, -> { 'rbenv sudo passenger-config restart-app' }

    set :monit_max_swap_size,     -> { '25%' }
    set :monit_max_memory_size,   -> { '75%' }
    set :monit_restart_passenger, -> do
      command = [fetch(:passenger_restart_command), fetch(:passenger_restart_options)].join(' ')
      "/usr/bin/sudo -u deployer -H sh -c '/home/deployer/.rbenv/bin/#{command}'"
    end

    set :whenever_identifier,    -> { fetch(:deploy_dir) }
    set :whenever_batch_scripts, -> { [] }

    append :linked_files, 'config/secrets.yml'
    append :linked_dirs, *%w(
      log
      tmp/pids
      tmp/cache
      tmp/sockets
      tmp/backups
      public/system
    )
  end
end
