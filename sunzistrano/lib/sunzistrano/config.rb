module Sunzistrano
  class Config < OpenStruct
    LIST_NAME = 'all'
    VARIABLES = /__([A-Z0-9_]+)__/
    DONE_ARG = '$1'
    DONE = "Done [#{DONE_ARG}]"

    constants.each do |name|
      define_method name do
        self.class.const_get name
      end
    end

    SunCap.config.sunzistrano.each do |name, value|
      define_method name do
        value
      end
    end

    def self.provision_yml
      Pathname.new(File.expand_path('config/provision.yml'))
    end

    # sudo apt-cache policy <package>
    def self.provision_yml_defaults
      {
        apt_ruby:       -> { '1:2.3.0+1' },
        postgres:       -> { '9.6.6-1.pgdg16.04+1' },
        nodejs:         -> { '6' },
        docker:         -> { '17.06.2~ce-0~ubuntu' },
        docker_compose: -> { '1.16.1' },
        docker_ctop:    -> { '0.6.1' },
      }
    end

    provision_yml_defaults.each do |name, value|
      define_method name do
        self[name] || instance_exec(&value)
      end
    end

    def initialize(stage, role, options)
      capistrano = Capistrano.load(stage)
      @stage, @application, app_root = capistrano.slice(:stage, :application, :app_root).values
      @role = role
      settings = SettingsYml.with_clean_env(env: @stage, app: @application, root: app_root || ENV['RAILS_ROOT'] || '')
      yml = YAML.load(ERB.new(self.class.provision_yml.read).result(binding))
      yml = (yml['shared'] || {}).merge!(yml[@role] || {})
      env_yml = yml.delete('stages') || {}
      env_yml = (env_yml['shared'] || {}).merge!(env_yml[@stage] || {})
      yml.merge!(env_yml)
      if @application
        app_yml = (yml.delete('applications') || {})[@application] || {}
        app_yml = (app_yml['shared'] || {}).merge!(app_yml[@stage] || {})
        yml.merge!(app_yml)
      end
      %i(lock gems).each do |name|
        yml["settings_#{name}"] = settings.delete(name)
      end
      super(capistrano.merge!(settings).merge!(yml).merge!(role: @role).merge!(options))
    end

    def vagrant_ssh?
      env.vagrant? && vagrant_ssh
    end

    def vagrant_ssh
      if (value = self[:vagrant_ssh]).to_b?
        value.to_b ? '' : nil
      else
        value
      end
    end

    def username
      if (value = self[:username]).present?
        value
      else
        sudo ? admin_name : 'deployer'
      end
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(stage.to_s)
    end

    def local_dir
      if local_path.present?
        @_local_dir ||= Pathname.new(local_path).expand_path
      end
    end

    def pkey
      @_pkey ||=
        if env.vagrant?
          `vagrant ssh-config #{vagrant_ssh}`.split("\n").drop(1).map(&:strip).each_with_object({}){ |key_value, configs|
            key, value = key_value.split(' ', 2)
            configs[key.underscore] = value
          }['identity_file']
        else
          self[:pkey]
        end
    end

    def rbenv_export
      self[:rbenv_export] || SunCap.rbenv_export
    end

    def rbenv_init
      self[:rbenv_init] || SunCap.rbenv_init
    end

    def role_recipes(*names)
      recipes = Array.wrap(*names) + (add_recipes || []).compact
      if (reboot = recipes.delete('reboot'))
        recipes << reboot
      end
      list_recipes(recipes) do |name, id|
        yield name, id
      end
    end

    def list_recipes(*names)
      recipes = Array.wrap(*names) - (skip_recipes || []).compact
      if recipe.present?
        recipes.select! do |name|
          name.end_with?("/#{LIST_NAME}") || name == recipe
        end
      end
      recipes.reject(&:blank?).each do |name|
        yield name, gsub_variables(name)
      end
    end

    def gsub_variables(name)
      has_variables = false
      segments = name.gsub(VARIABLES) do |segment|
        has_variables = true
        segment.gsub!(/(^__|__$)/, '').downcase!
        (value = try(segment)) ? "-#{value}" : ''
      end
      "'#{segments}'" if has_variables
    end
  end
end
