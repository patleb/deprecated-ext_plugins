require 'active_support/all'
require 'ext_ruby'
require 'yaml'
require 'inifile'
require 'settings_yml/version'
require 'settings_yml/type'
require 'settings_yml/railtie' if defined?(Rails)

class SettingsYml
  include Type

  DIRECT = /[a-zA-Z_][a-zA-Z0-9_]+/
  NESTED = /\[.+\]/
  CIPHER = 'aes-128-gcm'
  SECRET = '-----SECRET-----'

  def self.[](name)
    value = (@all || with)[name]
    cast(value, @types[name])
  end

  def self.has_key?(name)
    (@all || with).has_key? name
  end
  singleton_class.send :alias_method, :key?, :has_key?

  def self.slice(*names)
    names.each_with_object({}.with_indifferent_access) do |name, memo|
      memo[name] = self[name]
    end
  end

  def self.type_of(name)
    with unless @all
    (@types[name] || :text).to_sym
  end

  def self.rollback!
    if @all_was
      @all, @env, @app, @root, @encryptor = @all_was, @env_was, @app_was, @root_was, @encryptor_was
      @all_was = @env_was = @app_was = @root_was = @encryptor_was = nil
    end
    @all
  end

  def self.with_clean_env(env: ENV['RAILS_ENV'], app: ENV['RAILS_APP'], root: ENV['RAILS_ROOT'] || '', force: false)
    if force
      @all_was, @env_was, @app_was, @root_was, @encryptor_was = @all, @env, @app, @root, @encryptor
      @all = @env = @app = @root = nil
      remove_instance_variable :@encryptor
      with(env: env, app: app, root: root, clean_env: true)
    else
      @all || with(env: env, app: app, root: root, clean_env: true)
    end
  end
  singleton_class.send :alias_method, :clean, :with_clean_env

  def self.with(env: rails_env, app: rails_app, root: rails_root, clean_env: false)
    @all ||= begin
      raise 'environment must be specified or configured' unless env

      @env = env.to_s
      @app = app
      @root = Pathname.new(root).expand_path
      @types = {}.with_indifferent_access
      @rails_context = !clean_env
      secrets, database = rails_secrets_and_database
      settings = extract_yml(:settings, @root, secrets)

      validate_version! settings['lock']

      (settings['gems'] || []).each do |name|
        database.merge! parse_settings_yml(secrets, Pathname.new(gem_root(name)))
      end
      database.merge! parse_settings_yml(secrets, settings)
      secrets.merge! database
    end
  end
  singleton_class.send :alias_method, :all, :with

  def self.all=(hash)
    @all = hash
  end

  def self.encrypt(value)
    raise "secrets.yml ['secret_key_base'] is missing" unless encryptor
    SECRET + encryptor.encrypt_and_sign(value.escape_newlines)
  end

  def self.decrypt(value)
    raise "secrets.yml ['secret_key_base'] is missing" unless encryptor
    encryptor.decrypt_and_verify(value.sub(/^#{SECRET}/, '')).unescape_newlines
  end

  private_class_method

  def self.rails_context?
    @rails_context
  end

  def self.rails_env
    if @env
      @env
    elsif ENV['RAILS_ENV']
      ENV['RAILS_ENV']
    elsif defined?(Rails.env)
      Rails.env
    else
      nil
    end
  end

  def self.rails_app
    if @app
      @app
    elsif ENV['RAILS_APP']
      ENV['RAILS_APP']
    elsif defined?(Rails.application.engine_name)
      Rails.application.engine_name.sub(/_application$/, '')
    else
      nil
    end
  end

  def self.rails_root
    if @root
      @root
    elsif ENV['RAILS_ROOT']
      ENV['RAILS_ROOT']
    elsif defined?(Rails.root)
      Rails.root || ''
    else
      ''
    end
  end

  def self.rails_secrets_and_database
    secrets =
      if rails_context? && defined?(Rails.application)
        Rails.application.secrets.with_indifferent_access
      else
        extract_yml(:secrets, @root).with_indifferent_access
      end
    database =
      if rails_context? \
      && (base = (defined?(ApplicationRecord) && ApplicationRecord) || (defined?(ActiveRecord::Base) && ActiveRecord::Base))
        scope_database_keys base.connection_config
      else
        parse_database_yml(secrets)
      end
    [secrets, database]
  end

  def self.gem_root(name)
    path =
      if rails_context?
        Gem.loaded_specs[name].try(:gem_dir)
      else
        Dir.chdir(@root){ bundle_show(name) }
      end
    path or raise "gem [#{name}] not found"
  end

  def self.bundle_show(name)
    path = Pathname.new(`bundle show #{name}`.strip).expand_path
    path if path.directory?
  end

  def self.encryptor(secrets = nil)
    if defined? @encryptor
      @encryptor
    elsif (key = (secrets || with_clean_env)[:secret_key_base])
      size = ActiveSupport::MessageEncryptor.key_len(CIPHER)
      @encryptor = ActiveSupport::MessageEncryptor.new([key[0...(size*2)]].pack("H*"), cipher: CIPHER)
    else
      @encryptor = false
    end
  end

  def self.parse_database_yml(secrets)
    yml = extract_yml(:database, @root, secrets)
    scope_database_keys(yml)
  end

  def self.scope_database_keys(database)
    database.each_with_object({}) do |(key, value), memo|
      memo["db_#{key}"] = value
    end
  end

  def self.parse_settings_yml(secrets, root_or_settings)
    if root_or_settings.is_a? Hash
      settings = root_or_settings
    else
      settings = extract_yml(:settings, root_or_settings, secrets)
    end

    encryptor(secrets) ? gsub_settings_secrets(settings) : settings
  end

  def self.extract_yml(type, root, secrets = nil)
    path = root.join('config', "#{type}.yml")

    return {} unless File.exist?(path)

    yml = secrets ? (gsub_rails_secrets(path, secrets)) : path.read
    yml = YAML.load(ERB.new(yml).result)
    @types.merge!(yml['types'] || {})
    yml = (yml['shared'] || {}).merge!(yml[@env] || {})
    if @app
      app_yml = (yml.delete('applications') || {})[@app] || {}
      app_yml = (app_yml['shared'] || {}).merge!(app_yml[@env] || {})
      yml.merge!(app_yml)
    end
    yml
  end

  def self.gsub_rails_secrets(path, secrets)
    path.read.gsub(/<%=\s*Rails\.application\.secrets\.(#{DIRECT})(#{NESTED})?\s*%>/) do |match|
      eval("secrets[:#{$1}]#{$2}")
    end
  end

  def self.gsub_settings_secrets(settings)
    settings.each_with_object({}) do |(key, value), memo|
      if value.is_a?(String) && value.start_with?(SECRET)
        begin
          memo[key] = decrypt(value)
        rescue ActiveSupport::MessageEncryptor::InvalidMessage
          raise ActiveSupport::MessageEncryptor::InvalidMessage,
            "secrets.yml ['secret_key_base'] or settings.yml ['#{key}'] #{SECRET}* is invalid"
        end
      else
        memo[key] = value
      end
    end
  end

  def self.validate_version!(lock)
    unless lock == SettingsYml::VERSION
      raise "SettingsYml version [#{SettingsYml::VERSION}] is different from locked version [#{lock}]"
    end
  end
end
