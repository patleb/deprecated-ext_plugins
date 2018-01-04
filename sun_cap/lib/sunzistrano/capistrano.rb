module Sunzistrano
  module Capistrano
    def self.load(stage)
      env, app = stage.split(':', 2)

      @all = { stage: env, application: app }.with_indifferent_access

      deploy_path = File.expand_path('config/deploy.rb')
      instance_eval(File.read(deploy_path), deploy_path)

      env_path = File.expand_path("config/deploy/#{env}.rb")
      instance_eval(File.read(env_path), env_path)

      if app
        app_config_path = File.expand_path("config/deploy/applications/#{app}.rb")
        instance_eval(File.read(app_config_path), app_config_path) if File.exist?(app_config_path)

        stage_app_config_path = File.expand_path("config/deploy/#{env}/#{app}.rb")
        instance_eval(File.read(stage_app_config_path), stage_app_config_path) if File.exist?(stage_app_config_path)
      end

      if (output = `bundle exec cap #{stage} sun_cap:config --dry-run`.strip).blank?
        puts %{cap #{stage} sun_cap:config => ""}.color(:red).bright
      end
      output.split("\n").each do |key_value|
        key, value = key_value.strip.split(' ', 2)
        @all[key] = value
      end

      @all
    end

    def self.set(key, value)
      @all[key] = value
    end

    def self.fetch(key, value = nil)
      if @all.has_key?(key)
        @all[key]
      else
        @all[key] = value
      end
    end

    def self.method_missing(name, *args, &block)
      if caller.join.include? 'load'
        # do nothing
      else
        super
      end
    end
  end
end
